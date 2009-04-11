class DataProviders::MemInfo
  def initialize
    @readings = []
    @mutex = Mutex.new

    @thread = Thread.new do
      while(true)
        out = {}
        out[:total], out[:free], out[:buffers], out[:cached] = IO.readlines("/proc/meminfo")[0..4].map { |l| l =~ /^.*?\: +(.*?) kB$/; $1.to_i / 1024.0 }
        out[:free_total] = out[:free] + out[:buffers] + out[:cached]

        @mutex.synchronize do
          @readings.unshift(out)
          @readings.pop while @readings.length > 5
        end
        sleep(2.5)
      end
    end
  end

  def get
    out = {}
    @mutex.synchronize do
      out = @readings.first
      out[:status] = 'warning' unless @readings.detect { |r| r[:free] > 5 }
      out[:status] = 'danger' unless @readings.detect { |r| r[:free_total] > 1 }
    end
    out.formatted
  end

  def renderer
    information.merge({ :contents => %{
"<div class='major_figure'><span class='title'>Free</span><span class='figure'>" + data_source['free'] + "</span><span class='unit'>mb</span></div>" +
"<div class='major_figure'><span class='title'>Free -buffers/cache</span><span class='figure'>" + data_source['free_total'] + "</span><span class='unit'>mb</span></div>" +
"<div class='major_figure'><span class='title'>Total</span><span class='figure'>" + data_source['total'] + "</span><span class='unit'>mb</span></div>"
} })
  end

  def information
    { :name => "Memory Info", :in_sentence => 'Memory Usage', :importance => importance }
  end

  def importance
    90
  end

  def kill
    @thread.kill
  end
end