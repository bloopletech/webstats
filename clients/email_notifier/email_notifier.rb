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