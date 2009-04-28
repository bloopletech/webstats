require 'net/http'

class DataProviders::UrlMonitor
  def initialize(settings)
    @settings = self.class.default_settings.merge(settings)

    @readings = {}

    @mutex = Mutex.new

    @thread = Thread.new do
      while(true)
        @settings[:urls].sort.each do |url|
          duration = -1
          works = false
          begin
            start = Time.now
            result = Net::HTTP.get(URI.parse(url))
            duration = Time.now - start
            works = true
          rescue Exception => e
          end
          @mutex.synchronize { @readings[url] = { :response_time => duration * 1000, :works => works } }
        end
        sleep(@settings[:update_rate])
      end
    end
          
  end

  def get
    out = {}
    @mutex.synchronize { out[:urls] = @readings.to_a.sort_by { |e| e[0] } }
    out[:urls].each do |(url, info)|
      out[:status] = 'warning' if !info[:works] or info[:response_time] > @settings[:warning_response_time_threshold] and !out[:status] == 'danger'
      out[:status] = 'danger' if !info[:works] or info[:response_time] > @settings[:danger_response_time_threshold]
    end
    out
  end

  def renderer
    information.merge({ :contents => %{
var temp = "";
for(var i = 0; i < data_source['urls'].length; i++)
{
   var ud = data_source['urls'][i][1];
   temp += "<div class='major_figure'><span class='title'>" + data_source['urls'][i][0] + "</span><span class='figure'>" +
    (!ud['works'] ? 'Failed</span>' : ud['response_time'] + "</span><span class='unit'>ms</span>") + "</div>";
}

sc.innerHTML = temp;
} })
  end

  def self.default_settings
    { :update_rate => 30, :warning_response_time_threshold => 5000, :danger_response_time_threshold => 15000, :urls => ['http://localhost/'] }
  end

  def information
    { :name => "URL Monitor", :in_sentence => "URL Monitor", :importance => 60 }
  end

  def kill
  end
end