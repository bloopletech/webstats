require 'rubygems'
require 'json'
require 'net/http'
require 'uri'
require 'Growl'

url = ARGV[0]

g = GrowlNotifier.new("Webstats for #{url}",['Webstats Notification'],nil,OSX::NSWorkspace.sharedWorkspace().iconForFileType_('unknown'))
g.register

meta_info = JSON.parse(Net::HTTP.get(URI.join(url, "information")))
#last_bad_count = 0

while(true)
  data = JSON.parse(Net::HTTP.get(URI.join(url, "update")))

  bad = data.sort { |a, b| b[1]['importance'].to_f <=> a[1]['importance'].to_f }.select { |(k, v)| !v['status'].nil? && v['status'] != '' }
#  if past_bads.detect { |pb| pb.length > 0 }
  has_warnings = bad.detect { |(k, v)| v['status'] == 'warning' }
  has_dangers = bad.detect { |(k, v)| v['status'] == 'danger' }
  
  title = []
  title << "Warnings" if has_warnings
  title << "Danger" if has_dangers
  title = title.join(" & ") + " for host #{URI.parse(url).host}"
  
  warnings_text = has_warnings ? "Warnings for #{bad.select { |(k, v)| v['status'] == 'warning' }.map { |(k, v)| meta_info[k]['in_sentence'] }.join(", ")}." : nil
  danger_text = has_dangers ? "Dangerous situation for #{bad.select { |(k, v)| v['status'] == 'danger' }.map { |(k, v)| meta_info[k]['in_sentence'] }.join(", ")}." : nil

  unless bad.empty?
    g.notify "Webstats Notification", title, [danger_text, warnings_text].compact.join(" "), nil, nil, true, (has_dangers ? 2 : 1)
  end

  sleep(10)
end