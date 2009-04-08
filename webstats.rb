require 'webrick'

exit if fork
$stdout = File.new('/dev/null', 'w')
$stderr = File.new('/dev/null', 'w')

class String
  def underscore
    self.gsub(/::/, '/').
     gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
     gsub(/([a-z\d])([A-Z])/,'\1_\2').
     tr("-", "_").
     downcase
  end
  alias_method :to_json, :inspect
end

class Numeric
  def formatted(precision = 1)
    rounded_number = (Float(self) * (10 ** precision)).round.to_f / 10 ** precision
    parts = ("%01.#{precision}f" % rounded_number).to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
    parts.join(".")
  end
  alias_method :to_json, :inspect
end

class Array
  def to_json
    "[#{map { |e| e.to_json }.join(',')}]"
  end
end

class Hash
  def to_json
    arr = []
    each_pair { |k, v| arr << "#{k.to_json}:#{v.to_json}" }
    "{#{arr.join(',')}}"
  end
end

class Symbol
  def to_json
    to_s.inspect
  end
end

module DataProviders
  DATA_SOURCES = {}
  def self.setup
    Dir.glob("data_providers/*.rb").each { |file| load file }
    DataProviders.constants.each do |c|
      c = DataProviders.const_get(c)
      DATA_SOURCES[c.to_s.gsub(/^DataProviders::/, '').underscore] = c.new if c.is_a? Class
    end
  end
end

DataProviders.setup

class Webstats < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    body = ""
    if req.path_info == '/'
      body << <<-EOF
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
  <head>
    <title>Webstats</title>
    <style type="text/css">
      * { margin: 0; padding: 0; font-family: "Lucida Grande", Helvetica, Arial, sans-serif; font-size: 100%; }
      body { font-size: 95%; }
      p { margin: 0 0 1em 0; }

      h1 { margin: 1em; }
      h1 span { font-size: 160%; font-weight: bold; }

      .source { width: 400px; border: 1px solid #000000; margin: 1em; }
      .source h2 { padding: 0 0.8em 0 0.8em; background-color: #C98300; }
      .source h2 span { font-size: 130%; font-weight: bold; padding: 0.2em 0; display: block; }
      .source .source_contents { margin: 0.8em; }
      .source .title { padding-right: 0.5em; }
      .source .major_figure { font-size: 130%; margin: 0.3em 0; }
      .source .major_figure .figure { font-size: 120%; font-weight: bold; font-family: Georgia, serif; }
      .source .major_figure .unit { font-family: Georgia, serif; font-size: 70%; }
      .source .minor_figure { font-family: Georgia, serif; }
      .source .divider { margin-left: 0.2em; margin-right: 0.2em; font-weight: normal; }
    </style>
    <script type="text/javascript">
       var http = null;

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
               var results = eval("(" + http.responseText + ")");
               if(!results) return;
EOF

      DataProviders::DATA_SOURCES.each_pair do |k, v|
        r = v.renderer
        body << %{data_source = results['#{k}']; document.getElementById('source_contents_#{k}').innerHTML = (#{r[:contents]});\n}
      end

body << <<-EOF
            }
         };

         window.setInterval("getLatest()", 5000);
         getLatest();
      }
    </script>
  </head>
  <body id="body">
    <div id="main">
      <h1><span>Stats for #{req.host}</span></h1>
EOF
      DataProviders::DATA_SOURCES.sort { |a, b| b[1].importance <=> a[1].importance }.each do |(k, v)|
        r = v.renderer
        body << %{<div class="source" id="source_#{k}"><h2><span>#{r[:name]}</span></h2><div class="source_contents" id="source_contents_#{k}">Loading...</div></div>}
      end

      body << <<-EOF
    </div>
  </body>
</html>
EOF
    elsif req.path_info == '/update'
      out = {}
      DataProviders::DATA_SOURCES.each_pair { |k, v| out[k] = v.get }
      body << out.to_json
    end

    res.body = body
    res['Content-Type'] = "text/html"
  end
end

s = WEBrick::HTTPServer.new(:Port => 9970)

death = proc do
  s.shutdown
  DataProviders::DATA_SOURCES.each_pair { |k, v| v.kill }
end
trap("INT", death)
trap("TERM", death)

s.mount("/", Webstats)
s.start