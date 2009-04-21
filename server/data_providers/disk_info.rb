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
    out = { :reads => @reads_sec / 1024.0, :writes => @writes_sec / 1024.0, :mounts => [] }

    mtab = IO.readlines("/etc/mtab").sort_by { |l| l.split[1] }
    mtab.map do |mp|
      parts = mp.split
      next unless parts[3].split(",").detect { |p| p == "rw" }
      du = get_disk_usage(parts[1])
      out[:mounts] << [parts[1], du] unless du['total'] == 0 or (du['total'] > 10485760 && (du['total'] - du['free'] <= 1048576))
    end

    out[:mounts].map do |mp|
      mp[1]['free'] /= (1024.0 * 1024)
      mp[1]['total'] /= (1024.0 * 1024)
      out[:status] = "warning" if mp[1]['free'] < 50 and mp[1]['total'] > 100 and out[:status] != 'danger'
      out[:status] = "danger" if mp[1]['free'] < 10 and mp[1]['total'] > 20
    end

    out
  end

  def renderer
    information.merge({ :name => "Disk Info", :in_sentence => "Disk Usage", :importance => importance, :contents => %{
var temp = "<div class='major_figure'><span class='title'>Reads</span><span class='figure'>" + data_source['reads'] + "</span><span class='unit'>mb/s</span></div>" +
"<div class='major_figure'><span class='title'>Writes</span><span class='figure'>" + data_source['writes'] + "</span><span class='unit'>mb/s</span></div>";
for(var i = 0; i < data_source['mounts'].length; i++)
{
   var mpd = data_source['mounts'][i][1];
   temp += "<div class='major_figure'><span class='title'>" + data_source['mounts'][i][0] + "</span><span class='figure'>" + mpd['free'] +
    "</span><span class='unit'>mb free</span><span class='divider'>/</span><span class='figure'>" + mpd['total'] +
     "</span><span class='unit'>mb total</span></div>";
}

sc.innerHTML = temp;
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

require File.dirname(__FILE__) + '/disk_info.so'