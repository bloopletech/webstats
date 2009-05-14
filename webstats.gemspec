# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{webstats}
  s.version = "0.10.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Brenton Fletcher"]
  s.date = %q{2009-05-15}
  s.description = %q{Monitor server CPU/Memory/Disk Usage/URL Loading, so that you can view those statistics on a web page, as well as providing an interface to client prorams to read those statistics.}
  s.email = %q{i@bloople.net}
  s.executables = ["webstats", "webstats_growl_notifier", "webstats_email_notifier"]
  s.extensions = ["server/data_providers/extconf.rb"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.textile"
  ]
  s.files = [
    "LICENSE",
    "README.textile",
    "Rakefile",
    "VERSION.yml",
    "bin/webstats",
    "bin/webstats_email_notifier",
    "bin/webstats_growl_notifier",
    "bloople@bloople.net",
    "clients/email_notifier/README.textile",
    "clients/email_notifier/email_notifier.rb",
    "clients/growl_notifier/Growl.rb",
    "clients/growl_notifier/README.textile",
    "clients/growl_notifier/growl_notifier.rb",
    "clients/simple_notifier.rb",
    "server/data_providers/cpu_info.rb",
    "server/data_providers/disk_activity.rb",
    "server/data_providers/disk_usage.c",
    "server/data_providers/disk_usage.rb",
    "server/data_providers/extconf.rb",
    "server/data_providers/mem_info.rb",
    "server/data_providers/url_monitor.rb",
    "server/webstats.rb",
    "webstats.gemspec"
  ]
  s.homepage = %q{http://github.com/bloopletech/webstats}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = [""]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Monitor server CPU/Memory/Disk Usage/URL Loading, so that you can view those statistics on a web page, as well as providing an interface to client prorams to read those statistics.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
