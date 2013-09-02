require 'errand'
require "RRD"

class IwinfoStat < GraphBase
  include SimpleRRD
  
  attr_accessor :base_dir
  attr_accessor :stat_params
  attr_accessor :iface_name
  attr_accessor :stations_rrd
  
  def initialize(node,conf,name,stat_params)
    super
    self.base_dir = conf_value(['dir'])
    self.iface_name = stat_params['iface'] if stat_params
    self.stations_rrd = "#{self.base_dir}/iwinfo-#{stat_params['iface']}/stations.rrd" if stat_params && stat_params['iface']
  end

  def summary
    {
      stations_now: self.stations_now,
      stations_1d: self.stations_1d,
      stations_30d: self.stations_30d
    }
  end


  def stations_now
    rrd = Errand.new(:filename => self.stations_rrd)
    result = rrd.fetch(:start => (Time.now - 60).to_i.to_s) #1 min back
    points = result[:data]["value"].select {|s| !s.nan?}
    points.inject{ |sum, el| sum + el }.to_f / points.size
  end
  
  def stations_1d
    rrd = Errand.new(:filename => self.stations_rrd)
    result = rrd.fetch(:start => (Time.now - 24*3600).to_i.to_s) #1d back (24 * 3600 secs)
    points = result[:data]["value"].select {|s| !s.nan?}
    points.inject{ |sum, el| sum + el }.to_f / points.size
  end
  
  def stations_30d
    rrd = Errand.new(:filename => self.stations_rrd)
    result = rrd.fetch(:start => (Time.now - 30*24*3600).to_i.to_s) #30d back (30 * 24 * 3600 secs)
    points = result[:data]["value"].select {|s| !s.nan?}
    points.inject{ |sum, el| sum + el }.to_f / points.size
  
  end
  
 def create_graph(width,height,end_time,no_summary)
      stations_rrd = self.stations_rrd
      graph = FancyGraph.build do
#        title pingGDef.name if pingGDef.name
        width width
        height height
        end_at Time.now
        start_at Time.now - end_time
        upper_limit 20
        lower_limit 0
        rigid true
        exponent 1
        y_label "#"
        
        stations = Def.new(:rrdfile => stations_rrd, :ds_name => 'value', :cf => 'AVERAGE')
        stations_pct = CDef.new(:rpn_expression => [100, stations, '*'])

	stations_color = "7FB37C" #Green
        stations_line = Line.new(:data => stations, :text => "Stations ", :width => 1, :color => stations_color)
        stations_area = Area.new(:data => stations, :color => stations_color, :alpha => '66')

   
	add_element(stations_line)
        add_element(stations_area)
        summary_elements(stations).each { |e| add_element(e) } unless no_summary
      end
      graph.generate
  end 
  def self.interfaces(node)
    base_dir = GraphBase.conf_value_stat(['stats','iwinfo','dir'],node)
    Dir["#{base_dir}/iwinfo-*"].map do |str|
	   str.split('iwinfo-')[-1]
    end
  end
  
end
