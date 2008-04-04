require 'start'

class ProcTitle
 
  def initialize(app)
    @app = app
  end
 
  def call(env)
    $0 = "thin [#{env['SERVER_PORT']}/-/-]: handling #{env['SERVER_NAME']}: #{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
    @app.call(env)
  end
 
end

Ramaze.trait[:essentials].delete Ramaze::Adapter
#Ramaze::Inform.loggers.first.log_levels = [:error, :info, :warn]
Ramaze::Inform.loggers = []
Ramaze::Global.sourcereload = nil
use ProcTitle
Ramaze.start :force => true, :load_engines => :Builder, :cache_alternative => {:sessions => Ramaze::MemcachedCache}
run Ramaze::Adapter::Base
