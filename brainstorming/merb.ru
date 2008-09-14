$KCODE = 'UTF8'

ENV['MERB_ENV'] = 'production'
require 'rubygems'

gem 'merb-core'
require 'merb-core'

Merb::Config.use { |c|
  c[:framework]           = { :public => [Merb.root / "public", nil] },
  c[:session_store]       = 'none',
  c[:exception_details]   = true
}

Merb::Router.prepare do |r|
  r.match('/').to(:controller => 'perf', :action =>'index')
end

class Perf < Merb::Controller
  def index
    "Hello World!"
  end
end

Merb.start

run Merb::Rack::Application.new