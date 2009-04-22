# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{webstats}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Brenton Fletcher"]
  s.date = %q{2009-04-22}
  s.description = s.summary = %q{Display server CPU/Memory/Disk Usage on a web page, suitable for remote performance monitoring.}
  s.email = %q{i@bloople.net}
  s.files = Dir['**/*']
  s.executables = ['webstats']
  s.extensions = ["server/data_providers/extconf.rb"]
  s.has_rdoc = false
  s.homepage = %q{http://github.com/bloopletech/webstats}
  s.require_paths = [""]
#  s.rubyforge_project = %q{grit}
  s.rubygems_version = %q{1.3.0}
end
