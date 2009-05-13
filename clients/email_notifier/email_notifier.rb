require File.dirname(__FILE__) + '/../simple_notifier'
daemonize!

class EmailNotifier < SimpleNotifier
  def initialize(settings = {}, read_config = true)
    @name = 'email_notifier'
    @no_settings_message = "Please edit ~/.webstats_clients and add some URLs to monitor and an email address to notfiy on"
    
    super(settings, read_config)
  end

  private
  def send_mail(subject, message)
    sm = @settings[:mail_server]

    msg = <<END_OF_MESSAGE
From: Webstats Email Notifier <#{@settings[:recipient]}>
To: #{@settings[:recipient]} <#{@settings[:recipient]}>
Subject: #{subject}
Date: #{Time.now.rfc2822}
Message-Id: <#{Time.now.to_i}.#{rand(10000000)}@#{sm[:domain]}>

#{message}
END_OF_MESSAGE

    Net::SMTP.start(sm[:address], sm[:port], sm[:domain], sm[:username], sm[:password], sm[:authentication]) { |smtp| smtp.send_message msg, @settings[:recipient], @settings[:recipient] }
  end

  def failed_url(url, password, exception)
    send_mail("Webstats Notification - Cannot load Webstats data", "Could not load #{url}#{!password.nil? ? " with password #{password}" : ""}, error was #{exception.message}. Will try again in 60 seconds.")
    sleep(60)
    true
  end

  def notify
    messages = []
    has_warnings = has_dangers = false

    @settings[:urls].each do |url|
      if !url[:bad].empty? and (url[:changed] or url[:time_past])
        has_warnings = !url[:warnings].empty?
        has_dangers = !url[:dangers].empty?

        title = []
        title << "Danger" if has_dangers
        title << "Warnings" if has_warnings
        title = title.join(" & ")

        warnings_text = !url[:warnings].empty? ? "Warnings for #{url[:bad].select { |(k, v)| v['status'] == 'warning' }.map { |(k, v)| url[:meta_info][k]['in_sentence'] }.join(", ")}." : nil
        danger_text = !url[:dangers].empty? ? "Dangerous situation for #{url[:bad].select { |(k, v)| v['status'] == 'danger' }.map { |(k, v)| url[:meta_info][k]['in_sentence'] }.join(", ")}." : nil

        host = URI.parse(url[:url]).host
        messages << "#{title} for #{host}\n#{"-" * (title.length + host.length + 5)}\n\n#{[danger_text, warnings_text].compact.join("\n")}\n\nCheck statistics online at #{url[:url]}"
      end
    end

    title = []
    title << "Danger" if has_dangers
    title << "Warnings" if has_warnings

    send_mail("Webstats Notification - #{title.join(" & ")}", messages.join("\n\n\n")) unless messages.empty?
  end
end

s = EmailNotifier.new()
s.start

=begin






require File.dirname(__FILE__) + '/../common'
prepare_client

load_settings('email_notifier', { 'email_addresses' => ['example@example.com'] }] }, "Please edit ~/.webstats_clients and add some email addresss to send to")

urls = $settings[:urls]
emails = $settings[:emails]

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






































require 'rubygems'
require 'net/smtp'
require 'net/dns/resolver'
require 'net/dns/rr'
require 'time'

def send_mail_hardcore(recipient, recipient_name, from, from_name, subject, message)
  username, domain = recipient.split('@', 2) #yeah yeah, username can contain @ sign, will fix later

  mxrs = Net::DNS::Resolver.new.mx(domain)
  if mxrs.empty?
    puts "No MX records on domain; bad domain name"
    return
  end

  msg = <<END_OF_MESSAGE
From: #{from_name || recipient_name} <#{from || recipient}>
To: #{recipient_name} <#{recipient}>
Subject: #{subject}
Date: #{Time.now.rfc2822}
Message-Id: <#{Time.now.to_i}.#{rand(10000000)}@#{domain}>

#{message}
END_OF_MESSAGE

  Net::SMTP.start(mxrs.first.exchange, 25, domain) { |smtp| smtp.send_message msg, recipient, recipient }
end

send_mail_hardcore(*ARGV)
=end