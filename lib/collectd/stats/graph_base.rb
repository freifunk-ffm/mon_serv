# Base class for all graphs
class GraphBase
  
  attr_accessor :conf
  attr_accessor :node
  attr_accessor :name
  attr_accessor :stat_params

  def initialize(node,conf,name,stat_params)
    self.conf = conf
    self.node = node
    self.name = name
    self.stat_params = stat_params
  end
  
  def check_rrd_readable(name)
    raise "Cannot open #{name} for read" unless File.readable?(name)
  end

  def conf_value(key_path)
    node = self.node
    value = self.conf
    key_path.each do |key|
      value = value[key]
    end
    ERB.new(value).result(binding)
  end
end