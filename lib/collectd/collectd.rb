require 'erb'
# Serves as A FACTORY!
class Collectd
  
  # For now, one collectd instance is supported, only
  # Empty Constructor, now settings for collectd
  def initialize()
  
  end
  
  #Stats
  def ping_stat(collectd_node)
    ps = PingStat.new(collectd_node,Collectd.config['stats']['ping'])
    ps
  end
    
  
  
  def supported_stats
    res = []
    Collectd.config['stats'].each_pair do |plugin,stanza|
      stanza['names'].each do |name|
        res << Stat.new(plugin,name)
      end
    end
    res
  end

  def rrd_path(plugin,name,node)
    template_str = Collectd.config['stats'][plugin]['path']
    template = ERB.new template_str
    Collectd.config['rrd_base'] + template.result(binding)
  end

  
  
  def set_ping_hosts(addresses)
    template_filename = Collectd.config['ping']['template']
    config_filename = Collectd.config['ping']['path']
    File.open(config_filename,'w') do |file|
      file.flock(File::LOCK_EX)
      File.open(template_filename, "r") do |t_f|
        str = t_f.read
        template = ERB.new str
        file.write template.result(binding)
      end
    end
    system Collectd.config['reload_cmd'] #Execute reload
  end

  private
  def self.config
    @@collectd_conf ||= YAML::load_file("#{Rails.root}/config/app.yml")['collectd']
  end
  
end