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
      collectd_node = node.to_collectd_node
      stat = conf.stat(collectd_node,"ping",nil,nil)
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
      format.json {render json: daat.to_json}
    end
  end
  
  def all
    conf = Collectd.new
    result = {}
    Node.all.each do |n|
      result[n.id_hex] = {
        ping: {},
        stations: {}
      }
      begin
        result[n.id_hex][:ping] = conf.stat(n.to_collectd_node,'ping',nil,nil).summary 
      rescue Exception => e
        logger.warn "Unable to build ping statistics for #{n.inspect}: #{e.inspect}"
      end

      IwinfoStat.interfaces(n.to_collectd_node).each do |iface|
        begin
          result[n.id_hex][:stations][iface] = conf.stat(n.to_collectd_node,'iwinfo',nil,{'iface' => iface}).summary
        rescue Exception => e
          logger.warn "Unable to build iwinfo statistics for #{n.inspect}: #{e.inspect}"
        end
      end
    end
    render json: result.to_json
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
    @stat_params = params[:stat]
    cn = @node.to_collectd_node
    respond_to do |format|
      format.png do 
        stat = conf.stat(cn,id,name,@stat_params)
        send_data stat.create_graph(width,height,secs,no_summary), :type => 'image/png',:disposition => 'inline'
      end
      # try building stat object - may not succeed - to few parameters atm ...
      format.html do 
        begin
          @stat = conf.stat(cn,id,name,@stat_params)
        rescue Exception => e
          logger.info "Unable to construct stat object for debugging purpose #{e.inspect} - don't panic"
        end
        render action: id 
      end
    end
  end
end
