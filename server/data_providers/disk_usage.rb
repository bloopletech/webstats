class DataProviders::DiskUsage
  def initialize
  end

  def get
    out = { :mounts => [] }

    mtab = IO.readlines("/etc/mtab").sort_by { |l| l.split[1] }
    mtab.map do |mp|
      parts = mp.split
      next unless parts[3].split(",").detect { |p| p == "rw" }
      du = get_disk_usage(parts[1])
      out[:mounts] << [parts[1], du] unless du['total'] == 0 or (du['total'] > 5242880 && ((du['total'] - du['free']) <= 1048576))
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
    information.merge({ :name => "Disk Usage by Mount Point", :in_sentence => "Disk Usage", :importance => importance, :contents => %{
var temp = "";
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
    { :name => "Disk Usage by Mount Point", :in_sentence => "Disk Usage", :importance => importance }
  end

  def importance
    80
  end

  def kill
  end
end

require File.dirname(__FILE__) + '/disk_usage.so'