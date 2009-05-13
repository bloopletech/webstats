require 'yaml'
require 'net/http'
require 'uri'
require 'thread'
require 'time'
require 'net/smtp'

def daemonize!
  return if $DAEMONIZE == false
  if $DEBUG
    Thread.abort_on_exception
  else
    if (pid = fork)
      Signal.trap('HUP', 'IGNORE')
      Process.detach(pid)
      exit
    end
  end
end

class Hash
  alias_method :undecorated_get, :[] unless method_defined?(:undecorated_get)
  def [](key)
    undecorated_get(key) or undecorated_get(key.is_a?(String) ? key.to_sym : key.to_s)
  end
end

class SimpleNotifier
  def initialize(settings = {}, read_config = true)
    @name ||= "notifier"
    @default_settings ||= {}
    
    if read_config
      config_file_path = File.expand_path("~/.webstats_clients")

      @settings = {}

      if File.exists?(config_file_path)
        @settings = YAML.load(IO.read(config_file_path))
        @settings ||= {}
      end
    
      unless @settings.key?(@name)
        @settings[@name] = { 'urls' => [{ 'url' => 'http://localhost:9970/', 'password' => nil }] }.merge(@default_settings).merge(settings)
        File.open(config_file_path, "w") { |f| YAML.dump(@settings, f) }

        puts @no_settings_message
        exit
      end
    
      @settings = @settings[@name]
    else
      @settings = settings
    end
  end

  def start
    @settings[:urls].each do |url|
      url[:mutex] = Mutex.new
      Thread.new do
        url[:mutex].synchronize { url.merge!({ :meta_info => make_request(URI.join(url[:url], "information"), url[:password]), :last_time => 0 }) }
      end
    end

    while(true)
      threads = []
      @settings[:urls].each do |url|
        threads << Thread.new do
          url[:mutex].synchronize do
            url[:data] = make_request(URI.join(url[:url], "update"), url[:password])
            url[:bad] = url[:data].sort { |a, b| b[1]['importance'].to_f <=> a[1]['importance'].to_f }.select { |(k, v)| !v['status'].nil? && v['status'] != '' }
            url[:last_warnings] = url[:warnings] || []
            url[:warnings] = url[:bad].select { |(k, v)| v['status'] == 'warning' }
            url[:has_warnings]= !url[:warnings].empty?
            url[:last_dangers] = url[:dangers] || []
            url[:dangers] = url[:bad].select { |(k, v)| v['status'] == 'danger' }
            url[:has_dangers] = !url[:dangers].empty?
            url[:changed] = (!url[:warnings].empty? || !url[:dangers].empty?) && (!url.key?(:changed) or (url[:warnings].length > url[:last_warnings].length) or (url[:dangers].length > url[:last_dangers].length))
            url[:time_past] = url[:last_time] != 0 && (Time.now - url[:last_time]) > 60
            url[:last_time] = Time.now if url[:changed] || url[:last_time].nil? || url[:time_past]
          end
        end
      end
      threads.each { |t| t.join }
      notify
      sleep(10)
    end
  end

  private
  def make_request(url, password)
    while(true)
      begin
        Net::HTTP.start(url.host, url.port) { |http|
          http.read_timeout = http.open_timeout = 15
          req = Net::HTTP::Get.new(url.request_uri)
          req.basic_auth 'webstats', password unless password.nil?
          return YAML.load(http.request(req).body)
        }
      rescue Exception => e
        return nil unless failed_url(url, password, e)
      end
    end
  end
end

