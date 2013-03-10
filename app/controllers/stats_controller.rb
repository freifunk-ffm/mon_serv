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
