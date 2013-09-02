class InterfaceErrorStat < GraphBase
  include SimpleRRD
  attr_accessor :collectd_node

  attr_accessor :graph_name
  attr_accessor :rrd_file

  def initialize(node,conf,name,stat_params)
    super
    dir = conf_value(["dir"])
    self.rrd_file = "#{dir}/if_errors-#{self.name}.rrd"
    check_rrd_readable(self.rrd_file)
  end

  
  def create_graph(w,h,end_time,no_summary)
      graph_name = self.graph_name
      rrd_file = self.rrd_file
      graph = FancyGraph.build do
        width    w
        height   h
        end_at   Time.now
        start_at start_at Time.now - end_time
        
        # TX
        tx_data = Def.new(:rrdfile => rrd_file, :ds_name=>'tx', :cf => 'AVERAGE')

        tx_color = "33A02C" #Green
        tx_line = Line.new(:data => tx_data, :text => "Sendefehler", :width => 1, :color => tx_color)
        tx_area = Area.new(:data => tx_data, :color => tx_color, :alpha => '66')
        add_element(tx_line)
        add_element(tx_area)
        summary_elements(tx_data).each { |e| add_element(e) } unless no_summary
 
        add_element(line_break) unless no_summary
 
        # RX
        rx_data = Def.new(:rrdfile => rrd_file, :ds_name=>'rx', :cf => 'AVERAGE')
        rx_color = "1F78B4" #Blue

        rx_minus = CDef.new(:rpn_expression => [-1, rx_data, '*'])
        rx_line = Line.new(:data => rx_minus, :text => "Empfangsfehler", :width => 1, :color => rx_color)
        rx_area = Area.new(:data => rx_minus, :color => rx_color, :alpha => '66')
        add_element(rx_line)
        add_element(rx_area)
        summary_elements(rx_data).each { |e| add_element(e) } unless no_summary
 
        
 
      end
      graph.generate
  end
end
