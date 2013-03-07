require 'erb'
class CollectdConfig
  
  
  # For now, one collectd instance is supported, only
  # Empty Constructor, now settings for collectd
  def initialize()
  
  end
  
  def set_ping_hosts(addresses)
    template_filename = CollectdConfig.config['ping']['template']
    config_filename = CollectdConfig.config['ping']['path']
    File.open(config_filename,'w') do |file|
      file.flock(File::LOCK_EX)
      File.open(template_filename, "r") do |t_f|
        str = t_f.read
        template = ERB.new str
        file.write template.result(binding)
      end
    end
    system CollectdConfig.config['reload_cmd'] #Execute reload
  end

  private
  def self.config
    @@collectd_conf ||= YAML::load_file("#{Rails.root}/config/app.yml")['collectd']
  end
  
end