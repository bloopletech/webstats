class DataProviders::MemInfo
  def get
    out = {}
    
    out[:total], out[:free], out[:buffers], out[:cached] = IO.readlines("/proc/meminfo")[0..4].map { |l| l =~ /^.*?\: +(.*?) kB$/; $1.to_i / 1024.0 }
    
    out
  end
end