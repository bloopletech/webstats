require File.dirname(__FILE__) + '/../simple_notifier'
daemonize!
require File.dirname(__FILE__) + '/Growl.rb'

class WGrowlNotifier < SimpleNotifier
  def initialize(settings = {}, read_config = true)
    @name = "growl_notifier"
    @no_settings_message = "Please edit ~/.webstats_clients and add some URLs to monitor"

    @g = GrowlNotifier.new("Webstats", ['Webstats Notification'], nil, OSX::NSWorkspace.sharedWorkspace().iconForFileType_('unknown'))
    @g.register
    
    super(settings, read_config)
  end
  
  private
  def failed_url(url, password, exception)
    @g.notify "Webstats Notification", "Cannot load Webstats data", "Could not load #{url}#{!password.nil? ? " with password #{password}" : ""}, error was #{exception.message}. Will try again in 60 seconds."
    sleep(60)
    true
  end

  def notify
    @settings[:urls].each do |url|
     if !url[:bad].empty? and (url[:changed] or url[:time_past])
       title = []
       title << "Danger" unless url[:dangers].empty?
       title << "Warnings" unless url[:warnings].empty?
       title = title.join(" & ") + " for host #{URI.parse(url[:url]).host}"

       warnings_text = !url[:warnings].empty? ? "Warnings for #{url[:bad].select { |(k, v)| v['status'] == 'warning' }.map { |(k, v)| url[:meta_info][k]['in_sentence'] }.join(", ")}." : nil
       danger_text = !url[:dangers].empty? ? "Dangerous situation for #{url[:bad].select { |(k, v)| v['status'] == 'danger' }.map { |(k, v)| url[:meta_info][k]['in_sentence'] }.join(", ")}." : nil

       @g.notify "Webstats Notification", title, [danger_text, warnings_text].compact.join(" "), nil, nil, true, (!url[:dangers].empty? ? 2 : 1)
     end
   end
  end
end

s = WGrowlNotifier.new()
s.start