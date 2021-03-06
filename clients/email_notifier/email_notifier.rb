require File.dirname(__FILE__) + '/../simple_notifier'
daemonize!

class EmailNotifier < SimpleNotifier
  def initialize(settings = {}, read_config = true)
    @name = 'email_notifier'
    @no_settings_message = "Please edit ~/.webstats_clients and add some URLs to monitor and an email address to notfiy on"
    
    super({ 'recipient' => '', 'mail_server' => { 'address' => 'localhost', 'domain' => 'localhost', 'port' => 25 } }.merge(settings), read_config)
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