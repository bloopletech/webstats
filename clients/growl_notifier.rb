require 'rubygems'
require 'ruby-growl'
require 'json'
require 'net/http'
require 'uri'

url = ARGV[0]

g = Growl.new "localhost", "Webstats for #{url}", ["Webstats Notification"]

meta_info = JSON.parse(Net::HTTP.get(URI.join(url, "information")))

while(true)
  puts "Pulling"
  result = Net::HTTP.get(URI.join(url, "update"))
  puts "Pulled, parsing"
  data = JSON.parse result
  puts "Parsed, #{data.inspect}"
  bad = data.sort { |a, b| puts "a: #{a.inspect}, b: #{b.inspect}";b['importance'].to_f <=> a['importance'].to_f }.select { |(k, v)| v['status'] != '' }
  has_warnings = bad.detect { |(k, v)| v['status'] == 'warning' }
  has_dangers = bad.detect { |(k, v)| v['status'] == 'danger' }
  
  title = []
  title << "Warnings" if has_warnings
  title << "Danger" if has_dangers
  title = title.join(" & ")
  
  warnings_text = has_warnings.empty? ? nil : "Warnings for #{bad.select { |(k, v)| v['status'] == 'warning' }.map { |(k, v)| meta_info[k]['in_sentence'] }.join(", ")}."
  danger_text = has_dangers.empty? ? nil : "Dangerous situation for #{bad.select { |(k, v)| v['status'] == 'danger' }.map { |(k, v)| meta_info[k]['in_sentence'] }.join(", ")}."
  
  unless bad.empty?
    g.notify "Webstats Notification", title, [danger_text, warnings_text].compact.join(" "), (has_dangers ? 2 : 1), true
  end
  
  puts "Sleeping"

  sleep(10)
end