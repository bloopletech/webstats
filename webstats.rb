=begin
require 'rubygems'
require 'camping'

Camping.goes :ServerStats

module ServerStats
  module Models
  end
  
  module Controllers
    class Index < R '/'
      def get
        @books = Book.all
        render :index
      end
    end
    class Update < R '/update'
      def get
        @books = Book.all
        render :index
      end
    end
  end
  
  module Views
  end
end
=end
class String
  #ripped from rails/active_support
  def underscore
   self.gsub(/::/, '/').
     gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
     gsub(/([a-z\d])([A-Z])/,'\1_\2').
     tr("-", "_").
     downcase
  end
end  

module DataProviders
end

data_sources = {}

Dir.glob("data_providers/*.rb").each { |file| load file }
DataProviders.constants.each do |c|
  c = DataProviders.const_get(c)
  data_sources[c.to_s.underscore] = c.new if c.is_a? Class
end

while(true)
  data_sources.each_pair do |k, v|
    puts v.get.inspect
  end
  sleep(1)
end