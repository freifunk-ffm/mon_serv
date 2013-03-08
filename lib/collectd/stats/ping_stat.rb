require 'simplerrd'
class PingStat
  include SimpleRRD
  
  attr_accessor :conf
  attr_accessor :collectd_node

  def initialize(collectd_node,conf)
    self.conf = conf
    self.collectd_node = collectd_node
  end
  
  def loss(time)
  end
  
  def rtt(time)
  end
  
  
  def create_ping_graph(width,height,end_time)
      node = self.collectd_node
      base_prefix = self.conf['dir'] + "/ping/ping"
      address_templ_str = conf['address']
      address = ERB.new(address_templ_str).result(binding)
      
      graph = FancyGraph.build do
#        title pingGDef.name if pingGDef.name
        width width
        height height
        end_at Time.now
        start_at end_time
        upper_limit 200
        lower_limit 0
        rigid true
        exponent 1
        y_label "ms"
        y2_label "% loss"
        y2_scale (100.0/200) # SCALE = 100%
        y2_shift 0

        drops = Def.new(:rrdfile => "#{base_prefix}_droprate-#{address}", :ds_name => 'value', :cf => 'AVERAGE')
        drops_pct = CDef.new(:rpn_expression => [100, drops, '*'])
        timing = Def.new(:rrdfile => "#{base_prefix}-#{address}", :ds_name=>'ping', :cf => 'AVERAGE')

        timing_99pct = VDef.new(:rpn_expression => [timing, 99, "PERCENT"])
        drops_99pct = VDef.new(:rpn_expression => [drops_pct, 99, "PERCENT"])

        timing_color = "FF7F00" #Orage
        timing_line = Line.new(:data => timing, :text => "Ping RTT (ms) ", :width => 1, :color => timing_color)
        timing_area = Area.new(:data => timing, :color => timing_color, :alpha => '66')

        drops_scaled = CDef.new(:rpn_expression => [drops, 400, "*"])

        drops_color = "E31A1C" #Red
        drops_line = Line.new(:data => drops_scaled, :text => "Packet loss (%)", :width => 1, :color => drops_color)
        drops_area = Area.new(:data => drops_scaled, :color => drops_color, :alpha => '66')

        add_element(timing_line)
        add_element(timing_area)
        summary_elements(timing).each { |e| add_element(e) } 
        timing_99text = GPrint.new(:value => timing_99pct, :text => "99%%: %8.2lf%S")
        add_element(timing_99text) 
        add_element(line_break) 

        add_element(drops_line)
        add_element(drops_area)
        summary_elements(drops_pct).each { |e| add_element(e) } 
        drops_99text = GPrint.new(:value => drops_99pct, :text => "99%%: %8.2lf%S")
        add_element(drops_99text) 
        add_element(line_break) 
      end
      graph.generate
  end
end