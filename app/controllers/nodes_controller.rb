class NodesController < ApplicationController
  before_filter :auth, :only => [:create, :update,:delete]
  # GET /nodes
  # GET /nodes.json
  def index
    @nodes = Node.all
    @rtt = {}
    conf = Collectd.new
    @nodes.each do |node|
      collectd_node = CollectdNode.new(node.id.to_s(16),node.link_local_address)
      @rtt[node] = conf.ping_stat(collectd_node).rtt(Time.now - 3600)
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @nodes }
    end
  end

  # GET /nodes/1
  # GET /nodes/1.json
  def show
    @node = Node.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @node }
    end
  end

  # GET /nodes/new
  # GET /nodes/new.json
  def new
    @node = Node.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @node }
    end
  end

  # GET /nodes/1/edit
  def edit
    @node = Node.find(params[:id])
  end

  # POST /nodes
  # POST /nodes.json
  def create
    @node = Node.new(params[:node])
    @node.id = params[:node][:id]
    respond_to do |format|
      if @node.save
        format.html { redirect_to @node, notice: 'Node was successfully created.' }
        format.json { render json: @node, status: :created, location: @node }
      else
        format.html { render action: "new" }
        format.json { render json: @node.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /nodes/1
  # PUT /nodes/1.json
  def update
    @node = Node.find(params[:id])

    respond_to do |format|
      if @node.update_attributes(params[:node])
        format.html { redirect_to @node, notice: 'Node was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @node.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /nodes/1
  # DELETE /nodes/1.json
  def destroy
    @node = Node.find(params[:id])
    @node.destroy

    respond_to do |format|
      format.html { redirect_to nodes_url }
      format.json { head :no_content }
    end
  end
  
  ## Add macs, if not existing
  def add_macs
     params[:mac].each do |mac_str|
     mac = mac_str.to_i(16)
     unless Node.find_by_id(mac)
       n = Node.new
       n.id = mac
       begin
         n.save!
       rescue Exception => e
         logger.error "Node #{mac} / #{mac_str} cannot be added #{e}"
       end
     end
   end
   render json: "ok", status: :created
 end
end
