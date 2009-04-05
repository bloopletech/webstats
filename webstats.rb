require 'rubygems'
require 'rack'
require 'mongrel'

class String
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

class Webstats
  def initialize
    @data_sources = {}

    Dir.glob("data_providers/*.rb").each { |file| load file }
    DataProviders.constants.each do |c|
      c = DataProviders.const_get(c)
      @data_sources[c.to_s.gsub(/^DataProviders::/, '').underscore] = c.new if c.is_a? Class
    end
  end

  def call(env)
    req = Rack::Request.new(env)
    res = Rack::Response.new

    if req.path_info == '/'
      res.write <<-EOF
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
  <head>
    <title>Webstats</title>
    <style type="text/css">
      * { margin: 0; padding: 0; font-family: "Lucida Grande", Helvetica, Arial, sans-serif; font-size: 100%; }
      body { padding: 1em 1em 0 1em; font-size: 95%; }
      p { margin: 0 0 1em 0; }
      ul { margin: -0.5em 0 1em 0; padding-left: 2.5em; }
      li { margin: 0.1em; }
      h1 { margin: -1em -1em 0.1em -1em; padding: 1em; background-color: #0033CC; color: #ffffff; font-weight: bold; }
      h1 span { font-size: 200%; }
      h2 { margin: 1em 0; border-bottom: 2px solid #C98300; font-weight: bold; }
      h2 span { font-size: 115%; }
      #footer { margin: 1.1em -1em -1em -1em; padding: 1em; background-color: #0033CC; color: #ffffff; }
      #footer a { color: #BFCFFF; }
    </style>
    <script type="text/javascript">
       var http = null;

       function escapeHTML(str)
       {
          //code portion borrowed from prototype library
          var div = document.createElement('div');
          var text = document.createTextNode(str);
          div.appendChild(text);
          return div.innerHTML;
          //end portion
       }

       function getLatest()
       {
          http.open("get", "/update", true);
          http.send(null);
       }

       window.onload = function()
       {
          http = !!(window.attachEvent && !window.opera) ? new ActiveXObject("Microsoft.XMLHTTP") : new XMLHttpRequest();

          http.onreadystatechange = function()
          {
            if(http.readyState == 4)
            {
               document.getElementById("body").innerHTML = escapeHTML(http.responseText);
            }
         };

         window.setInterval("getLatest()", 5000);
      }
    </script>
  </head>
  <body id="body">
  </body>
</html>
EOF
    elsif req.path_info == '/update'
      out = {}
      @data_sources.each_pair { |k, v| out[k] = v.get }
      res.write out.inspect
    end

    res.finish
  end
end

Rack::Handler::Mongrel.run(Webstats.new, { :Port => 9970 })