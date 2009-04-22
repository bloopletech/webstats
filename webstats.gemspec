# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{webstats}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Brenton Fletcher"]
  s.date = %q{2009-04-22}
  s.default_executable = %q{webstats}
  s.description = %q{Display server CPU/Memory/Disk Usage on a web page, suitable for remote performance monitoring.}
  s.email = %q{i@bloople.net}
  s.executables = ["webstats"]
  s.extensions = ["server/data_providers/extconf.rb"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README"
  ]
  s.files = [
    "LICENSE",
    "README",
    "Rakefile",
    "VERSION.yml",
    "bin/webstats",
    "clients/email_notifier/email_notifier.rb",
    "clients/growl_notifier/Growl.rb",
    "clients/growl_notifier/growl_notifier.rb",
    "server/data_providers/cpu_info.rb",
    "server/data_providers/disk_activity.rb",
    "server/data_providers/disk_info.o",
    "server/data_providers/disk_usage.c",
    "server/data_providers/disk_usage.o",
    "server/data_providers/disk_usage.rb",
    "server/data_providers/extconf.rb",
    "server/data_providers/mem_info.rb",
    "server/webstats.rb",
    "webstats.gemspec"
  ]
  s.homepage = %q{http://github.com/bloopletech/webstats}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = [""]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Display server CPU/Memory/Disk Usage on a web page, suitable for remote performance monitoring.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
