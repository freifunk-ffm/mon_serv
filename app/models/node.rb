require 'netaddr'

class Node < ActiveRecord::Base
  attr_accessible :alert_addresses, :ip_address
  after_save :update_collectd
  
  def id_hex 
    "%012x" % self.id
  end
  
  def update_collectd
    conf = CollectdConfig.new
    conf.set_ping_hosts(Node.all.map(&:link_local_address))
  end
  
  def link_local_address
    NetAddr::EUI48.new(self.id).link_local
  end

end
