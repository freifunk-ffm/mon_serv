require 'errand'
require "RRD"

class PingStat < GraphBase
  include SimpleRRD
  

  attr_accessor :drop_rrd
  attr_accessor :rtt_rrd
  

  def initialize(node,conf,name,stat_params)
    super
    base_prefix = conf['dir'] + "/ping/ping"
    address = conf_value(['address'])
    
    self.drop_rrd = "#{base_prefix}_droprate-#{address}"
    self.rtt_rrd = "#{base_prefix}-#{address}"
    check_rrd_readable(self.drop_rrd)
    check_rrd_readable(self.rtt_rrd)
    
  end
  
  def all_stats(start_t,end_t,interval)
    (fstart, fend, data, step) = RRD.fetch(self.rtt_rrd, 
      "--start", start_t.to_s, 
      "--end", end_t.to_s, 
      "--resolution", interval.to_s,"AVERAGE")
    {fstart: fstart, fend: fend, data: data, step: step}
  end
  
  def summary
    {
      loss_5_min: self.loss_5_min,
      rtt_5_min: self.rtt_5_min
    }
  end

  # Early collectd: ping
  # Later collectd: value
  def ping_ds_name
    unless @ping_ds_name 
      @ping_ds_name = all_stats((Time.now - 1).to_i, Time.now.to_i, 1)[:data][0]
    end
    @ping_ds_name 
  end

  def loss_5_min
    rrd = Errand.new(:filename => drop_rrd)
    result = rrd.fetch(:start => (Time.now - 300).to_i.to_s) #5 min back
    points = result[:data]['value'].select {|s| !s.nan?}
    points.inject{ |sum, el| sum + el }.to_f / points.size
    
  end
  
  def rtt_5_min
    rrd = Errand.new(:filename => rtt_rrd)
    result = rrd.fetch(:start => (Time.now - 300).to_i.to_s) #5 min back
    points = result[:data][self.ping_ds_name].select {|s| !s.nan?}
    points.inject{ |sum, el| sum + el }.to_f / points.size
  end
  
  
  def create_graph(width,height,end_time,no_summary)
      drop_rrd = self.drop_rrd
      rtt_rrd = self.rtt_rrd
      ping_ds_name = self.ping_ds_name
      graph = FancyGraph.build do
#        title pingGDef.name if pingGDef.name
        width width
        height height
        end_at Time.now
        start_at Time.now - end_time
        upper_limit 500
        lower_limit 0
        rigid true
        exponent 1
        y_label "ms"
        y2_label "% loss"
        y2_scale (100.0/500) # SCALE = 100%
        y2_shift 0

        drops = Def.new(:rrdfile => drop_rrd, :ds_name => 'value', :cf => 'AVERAGE')
        drops_pct = CDef.new(:rpn_expression => [100, drops, '*'])
        timing = Def.new(:rrdfile => rtt_rrd, :ds_name=> ping_ds_name, :cf => 'AVERAGE')

        timing_99pct = VDef.new(:rpn_expression => [timing, 99, "PERCENT"])
        drops_99pct = VDef.new(:rpn_expression => [drops_pct, 99, "PERCENT"])

        timing_color = "FF7F00" #Orange
        timing_line = Line.new(:data => timing, :text => "Ping RTT (ms) ", :width => 1, :color => timing_color)
        timing_area = Area.new(:data => timing, :color => timing_color, :alpha => '66')

        drops_scaled = CDef.new(:rpn_expression => [drops, 500, "*"])

        drops_color = "E31A1C" #Red
        drops_line = Line.new(:data => drops_scaled, :text => "Packet loss (%)", :width => 1, :color => drops_color)
        drops_area = Area.new(:data => drops_scaled, :color => drops_color, :alpha => '66')

        add_element(timing_line)
        add_element(timing_area)
        summary_elements(timing).each { |e| add_element(e) } unless no_summary
        timing_99text = GPrint.new(:value => timing_99pct, :text => "99%%: %8.2lf%S")
        add_element(timing_99text) unless no_summary
        add_element(line_break) unless no_summary

        add_element(drops_line)
        add_element(drops_area)
        summary_elements(drops_pct).each { |e| add_element(e) } unless no_summary
        drops_99text = GPrint.new(:value => drops_99pct, :text => "99%%: %8.2lf%S")
        add_element(drops_99text) unless no_summary
        add_element(line_break) unless no_summary
      end
      graph.generate
  end
end
