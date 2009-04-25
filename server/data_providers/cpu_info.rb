class DataProviders::CpuInfo
  def initialize(settings)
    @settings = self.class.default_settings.merge(settings)

    @readings = []
    @mutex = Mutex.new

    @thread = Thread.new do
      last_time = last_user = last_nice = last_system = last_idle = last_iowait = 0
      first_time = true
      while(true)
        time = (Time.new.to_f * 1000).to_i

        user, nice, system, idle, iowait, crap = IO.readlines("/proc/stat").first.split(' ', 6).map { |i| i.to_i }

        if first_time
          first_time = false
        else
          temp_user = (user - last_user)
          temp_nice = (nice - last_nice)
          temp_system = (system - last_system)
          temp_idle = (idle - last_idle)
          temp_iowait = (iowait - last_iowait)

          @mutex.synchronize do
            @readings.unshift((temp_user + temp_nice + temp_system) / (temp_idle.to_f < 1 ? 1 : temp_idle.to_f))
            @readings.pop while @readings.length > 5
          end
        end
        last_user = user
        last_nice = nice
        last_system = system
        last_idle = idle
        last_iowait = iowait
        last_time = time
        sleep(@settings[:update_rate])
      end
    end
  end  
    
  def get
    out = { :usage => 0 }
    @mutex.synchronize do
      unless @readings.empty?
        out[:usage] = @readings.first
        out[:status] = 'warning' unless @readings.detect { |r| out[:usage] < @settings[:usage_warning_level] }
        out[:status] = 'danger' unless @readings.detect { |r| out[:usage] < @settings[:usage_danger_level] }
      end
    end
    out[:loadavg_1], out[:loadavg_5], out[:loadavg_15] = IO.readlines("/proc/loadavg").first.split(' ', 4).map { |v| v.to_f }
    out
  end

  def renderer
    information.merge({ :contents => %{
sc.innerHTML = "<div class='major_figure'><span class='title'>Usage</span><span class='figure'>" + data_source['usage'] + "</span><span class='unit'>%</span></div>" + 
"<div class='major_figure'><span class='title'>Load average</span><span class='figure'>" + data_source['loadavg_1'] +
"</span><span class='unit'>1m</span><span class='divider'>/</span><span class='figure'>" + data_source['loadavg_5'] +
"</span><span class='unit'>5m</span><span class='divider'>/</span><span class='figure'>" + data_source['loadavg_15'] + "</span><span class='unit'>15m</span></div>";
} })
  end

  def self.default_settings
    { :update_rate => 2.5, :usage_warning_level => 95, :usage_danger_level => 99.5 }
  end

  def information
    { :name => "CPU Info", :in_sentence => 'CPU load', :importance => 100 }
  end

  def kill
    @thread.kill
  end
end