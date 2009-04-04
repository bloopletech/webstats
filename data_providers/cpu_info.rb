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

#    user, nice, system, idle, iowait, crap = IO.readlines("/proc/stat").first.split(' ', 6).map { |i| i.to_i }
#    puts "user: #{user}, nice: #{nice}, system: #{system}, idle: #{idle}, iowait: #{iowait}"
#    out[:usage] = ((user + nice + system + iowait) / idle.to_f) * 100
    out[:usage] = @usage

    out[:loadvg_1], out[:loadvg_5], out[:loadvg_15] = IO.readlines("/proc/loadavg").first.split(' ', 4)
    
    out
  end
end