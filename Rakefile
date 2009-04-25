require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
      s.name = %q{webstats}
      s.version = "0.1.0"

      s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
      s.authors = ["Brenton Fletcher"]
      s.date = Date.today.strftime("%Y-%m-%d")
      s.description = s.summary = %q{Display server CPU/Memory/Disk Usage on a web page, suitable for remote performance monitoring.}
      s.email = %q{i@bloople.net}
      s.files = Dir['**/*'].reject { |fn| fn =~ /(\.o|\.so|Makefile)$/ }
      s.executables = ['webstats']
      s.extensions = ["server/data_providers/extconf.rb"]
      s.has_rdoc = false
      s.homepage = %q{http://github.com/bloopletech/webstats}
      s.require_paths = [""]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
