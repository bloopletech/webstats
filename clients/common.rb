class Hash
  alias_method :undecorated_get, :[]
  def [](key)
    undecorated_get(key) or undecorated_get(key.is_a?(String) ? key.to_sym : key.to_s)
  end
end

def load_settings(client_key, defaults, message)
  config_file_path = File.expand_path("~/.webstats_clients")

  $settings = {}

  if File.exists?(config_file_path)
    $settings = YAML.load(IO.read(config_file_path))[client_key]
  else
    $settings[client_key] = defaults

    File.open(config_file_path, "w") do |f|
      YAML.dump($settings, f)
    end

    puts message
    exit
  end
end

def make_request(url, password, failed_proc)
  while(true)
    begin
      Net::HTTP.start(url.host, url.port) { |http|
        http.read_timeout = http.open_timeout = 15
        puts url.request_uri
        req = Net::HTTP::Get.new(url.request_uri)
        req.basic_auth 'webstats', password unless password.nil?
        return JSON.parse(http.request(req).body)
      }
    rescue Exception => e
      return nil unless failed_proc.call(url, password, e)
    end
  end
end
  