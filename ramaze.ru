require 'start'

Ramaze.trait[:essentials].delete Ramaze::Adapter
#Ramaze::Log.loggers.first.log_levels = [:error, :info, :warn]
Ramaze::Log.loggers = []
Ramaze::Global.sourcereload = nil
use Rack::Static, :urls => ["/css", "/js"], :root => "public"
Ramaze.start! :load_engines => :Builder, :cache_alternative => {:sessions => Ramaze::MemcachedCache}
run Ramaze::Adapter::Base
