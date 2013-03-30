require 'netaddr'

class Node < ActiveRecord::Base
  attr_accessible :alert_addresses, :ip_address
  after_save :update_collectd
  
  def id_hex 
    "%012x" % self.id
  end
  
  def update_collectd
    conf = Collectd.new
    conf.set_ping_hosts(Node.all.map(&:link_local_address))
    # Set mac-Adresses
    macs_by_ll = {}
    
    Node.all.each do |node|
      macs_by_ll[node.link_local_address] = NetAddr::EUI48.new(node.id).address(:Delimiter => ':')
    end
    conf.write_mac_list macs_by_ll
    
  end
  
  def link_local_address
    NetAddr::EUI48.new(self.id).link_local
  end

end
