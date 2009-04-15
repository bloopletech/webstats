class DataProviders::DiskInfo
  def initialize
    @reads_sec = 0
    @writes_sec = 0

    @thread = Thread.new do
      last_time = last_reads = last_writes = 0
      first_time = true
      while(true)
        time = (Time.new.to_f * 1000).to_i

        reads, writes = IO.readlines("/proc/diskstats").map { |l| parts = l.split; [parts[5].to_i, parts[7].to_i] }.inject([0, 0]) { |sum, vals| [sum[0] + vals[0], sum[1] + vals[1]] }

        if first_time
          first_time = false
        else
          @reads_sec = ((reads - last_reads) / ((time - last_time).to_f / 1000.0)) * 512
          @writes_sec = ((writes - last_writes) / ((time - last_time).to_f / 1000.0)) * 512
        end
        last_reads = reads
        last_writes = writes
        last_time = time
        sleep(2.5)
      end
    end
  end

  def get
    { :reads => @reads_sec / 1024.0, :writes => @writes_sec / 1024.0 }
  end

  def renderer
    information.merge({ :name => "Disk Info", :in_sentence => "Disk Usage", :importance => importance, :contents => %{
"<div class='major_figure'><span class='title'>Reads</span><span class='figure'>" + data_source['reads'] + "</span><span class='unit'>mb/s</span></div>" +
"<div class='major_figure'><span class='title'>Writes</span><span class='figure'>" + data_source['writes'] + "</span><span class='unit'>mb/s</span></div>"
} })
  end

  def information
    { :name => "Disk Info", :in_sentence => "Disk Usage", :importance => importance }
  end

  def importance
    80
  end

  def kill
    @thread.kill
  end
end