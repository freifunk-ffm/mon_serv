class StatsController < ApplicationController
  def index
    @node = Node.find(params[:node_id])
    conf = Collectd.new
    collectd_node = CollectdNode.new(@node.link_local_address, @node.id.to_s(16))
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
    node = Node.find(params[:node_id])
    secs = (params[:secs] || 3600).to_i
     
    cn = CollectdNode.new(node.id.to_s(16),node.link_local_address,)
    #path = conf.rrd_path(params[:plugin],params[:name],cn)
    respond_to do |format|
      #format.rrd {send_file path, :type=>"application/rrd"}
      format.png {send_data conf.ping_stat(cn).create_ping_graph(600,200,-secs), :type => 'image/png',:disposition => 'inline'}
    end
  end
end
