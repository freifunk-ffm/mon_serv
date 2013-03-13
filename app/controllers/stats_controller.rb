class StatsController < ApplicationController
  
  def all_nodes
    start_t = (params[:start] || -60).to_i
    end_t = (params[:end] || Time.now).to_i
    interval = (params[:interval] || 15).to_i
    conf = Collectd.new
    data = {}
    Node.all.each do |node|
      collectd_node = CollectdNode.new(node.id_hex,node.link_local_address)
      stat = conf.stat(collectd_node,"ping",nil)
      result = stat.all_stats(start_t,end_t,interval)
      index = 0
      data[node.id] = []
      result[:steps].each do |res|
        current = result[:fstart].to_i + (index * interval)
        data[node.id] << [current,res]
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
    cn = CollectdNode.new(@node.id_hex,@node.link_local_address)
    respond_to do |format|
      format.png do 
        stat = conf.stat(cn,id,name)
        send_data stat.create_graph(width,height,secs), :type => 'image/png',:disposition => 'inline'
      end
      format.html { render action: id}
    end
  end
end
