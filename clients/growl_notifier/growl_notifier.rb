if true or $DEBUG
  Thread.abort_on_exception
else
  exit if fork
  $stdout = File.new('/dev/null', 'w')
  $stderr = File.new('/dev/null', 'w')
end

require 'rubygems'
require 'json'
require 'net/http'
require 'uri'
require File.dirname(__FILE__) + '/Growl.rb'

require File.dirname(__FILE__) + '/../common'
load_settings('growl_notifier', { 'urls' => [{ 'url' => '', 'password' => nil }] }, "Please edit ~/.webstats_clients and add some URLs to monitor")

urls = $settings[:urls]

g = GrowlNotifier.new("Webstats", ['Webstats Notification'], nil, OSX::NSWorkspace.sharedWorkspace().iconForFileType_('unknown'))
g.register

failed_url = lambda do |url, password, exception|
  g.notify "Webstats Notification", "Cannot load Webstats data", "Could not load #{url}#{!password.nil? ? " with password #{password}" : ""}, error was #{exception.message}. Will try again in 60 seconds."
  sleep(60)
  true
end

urls.each do |url|
  url.merge!({ :meta_info => make_request(URI.join(url[:url], "information"), url[:password], failed_url), :last_warnings_text => nil, :last_danger_text => nil, :last_time => 0 })
end

while(true)
  urls.each do |url|
    data = make_request(URI.join(url[:url], "update"), url[:password], failed_url)

    bad = data.sort { |a, b| b[1]['importance'].to_f <=> a[1]['importance'].to_f }.select { |(k, v)| !v['status'].nil? && v['status'] != '' }

    has_warnings = bad.detect { |(k, v)| v['status'] == 'warning' }
    has_dangers = bad.detect { |(k, v)| v['status'] == 'danger' }
  
    title = []
    title << "Danger" if has_dangers
    title << "Warnings" if has_warnings
    title = title.join(" & ") + " for host #{URI.parse(url[:url]).host}"
  
    warnings_text = has_warnings ? "Warnings for #{bad.select { |(k, v)| v['status'] == 'warning' }.map { |(k, v)| url[:meta_info][k]['in_sentence'] }.join(", ")}." : nil
    danger_text = has_dangers ? "Dangerous situation for #{bad.select { |(k, v)| v['status'] == 'danger' }.map { |(k, v)| url[:meta_info][k]['in_sentence'] }.join(", ")}." : nil

    if url[:last_warnings_text] != warnings_text or url[:last_danger_text] != danger_text or (url[:last_time] != 0 and (Time.now - url[:last_time]) > 60)
      url[:last_warnings_text] = warnings_text
      url[:last_danger_text] = danger_text
      url[:last_time] = Time.now

      unless bad.empty?
        g.notify "Webstats Notification", title, [danger_text, warnings_text].compact.join(" "), nil, nil, true, (has_dangers ? 2 : 1)
      end
    end
  end

  sleep(10)
end