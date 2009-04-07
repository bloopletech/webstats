class DataProviders::CpuInfo
  def initialize
    @usage = 0

    Thread.new do
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
          @usage = ((temp_user + temp_nice + temp_system) / (temp_idle.to_f < 1 ? 1 : temp_idle.to_f))
        end
        last_user = user
        last_nice = nice
        last_system = system
        last_idle = idle
        last_iowait = iowait
        last_time = time
        sleep(1)
      end
    end
  end  
    
  def get
    out = {}
    out[:usage] = @usage.formatted
    out[:loadavg_1], out[:loadavg_5], out[:loadavg_15] = IO.readlines("/proc/loadavg").first.split(' ', 4).map { |v| v.to_f.formatted }
    out
  end

  def renderer
    { :name => "CPU Info", :contents => %{
"<div class='major_figure'><span class='title'>Usage</span><span class='figure'>" + data_source['usage'] + "</span><span class='unit'>%</span></div>" + 
"<div class='major_figure'><span class='title'>Load average</span><span class='figure'>" + data_source['loadavg_1'] +
"</span><span class='unit'>1m</span><span class='divider'>/</span><span class='figure'>" + data_source['loadavg_5'] +
"</span><span class='unit'>5m</span><span class='divider'>/</span><span class='figure'>" + data_source['loadavg_15'] + "</span><span class='unit'>15m</span></div>"
} }
  end

  def importance
    100
  end
end