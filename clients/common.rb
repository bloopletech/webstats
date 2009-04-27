class Hash
  alias_method :undecorated_get, :[]
  def [](key)
    undecorated_get(key) or undecorated_get(key.is_a?(String) ? key.to_sym : key.to_s)
  end
end

def load_settings(defaults_key, defaults)
  config_file_path = File.expand_path("~/.webstats_clients")

  $settings = {}

  if File.exists?(config_file_path)
    $settings = YAML.load(IO.read(config_file_path))
  else
    $settings[defaults_key] = defaults

    File.open(config_file_path, "w") do |f|
      YAML.dump($settings, f)
    end

    puts "Please edit ~/.webstats_clients and add some URLs to monitor"
    exit
  end
end
  