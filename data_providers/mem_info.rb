class DataProviders::MemInfo
  def get
    out = {}
    out[:total], out[:free], out[:buffers], out[:cached] = IO.readlines("/proc/meminfo")[0..4].map { |l| l =~ /^.*?\: +(.*?) kB$/; $1.to_i / 1024.0 }
    out[:free_total] = out[:total] - out[:buffers] - out[:cached]
    out.each_pair { |k, v| out[k] = v.formatted }
    out
  end

  def renderer
    { :name => "Memory Info", :contents => %{
"<div class='major_figure'><span class='title'>Free</span><span class='figure'>" + data_source['free'] + "</span><span class='unit'>mb</span></div>" +
"<div class='major_figure'><span class='title'>Free -buffers/cache</span><span class='figure'>" + data_source['free_total'] + "</span><span class='unit'>mb</span></div>" +
"<div class='major_figure'><span class='title'>Total</span><span class='figure'>" + data_source['total'] + "</span><span class='unit'>mb</span></div>"
} }
  end

  def importance
    90
  end
end