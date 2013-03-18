class StatsController < ApplicationController
  
  def ping
    start_t = (params[:start] || -60).to_i
    interval = (params[:interval] || 10).to_i
    end_t = ((params[:end] || Time.now).to_i / interval) * interval

    conf = Collectd.new
    data = {}
    node_scope = Node.scoped
    if node_id = params[:node_id]
      node_scope = node_scope.where(id: node_id)
    end

    node_scope.each do |node|
      collectd_node = CollectdNode.new(node.id_hex,node.link_local_address)
      stat = conf.stat(collectd_node,"ping",nil)
      begin 
        result = stat.all_stats(start_t,end_t,interval)
        index = 1 # Not 0! -> = 0 will introduce off by one error, since starting at f_start means, the that first value is available at start+interval
        data[node.id] = []
        result[:step].each do |res|
          current = result[:fstart].to_i + (index * interval)
          data[node.id] << [current,(res.first.nan?) ? nil : res.first]
          index += 1
        end if result[:step]
      rescue Exception => e
        logger.warn "Data for #{node.id} is missing - #{e}"
      end
    end
    respond_to do |format|
      format.json {render json: data.to_json}
    end
  end
  
  def index
    @node = Node.find(params[:node_id])
    conf = Collectd.new
    collectd_node = CollectdNode.new(@node.link_local_address, @node.id_hex)
    @stats = conf.supported_stats    
    
    respond_to do |format|
      format.html
      format.json do
        stat_map = @stats.map {|s| {plugin: s.plugin, name: s.name, rrd: conf.rrd_path(s.plugin,s.name,collectd_node)}}
        render json: stat_map.to_json
      end
    end  
  end
  
  
  def show
    conf = Collectd.new
    @node = Node.find(params[:node_id])
    secs = (params[:secs] || 3600).to_i
    name = params[:name]
    type = params[:type]
    id = params[:id] || params[:type]
    width = params[:width] || 600
    height = params[:height] || 200
    no_summary = params[:no_summary]
    cn = CollectdNode.new(@node.id_hex,@node.link_local_address)
    respond_to do |format|
      format.png do 
        stat = conf.stat(cn,id,name)
        send_data stat.create_graph(width,height,secs,no_summary), :type => 'image/png',:disposition => 'inline'
      end
      format.html { render action: id}
    end
  end
end
