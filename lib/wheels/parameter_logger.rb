module Wheels
  class ParameterLogger

    def initialize(app)
      @app = app
    end

    def call(env)
      puts "#{'*'*40}\n#{env['REQUEST_METHOD']} #{env['PATH_INFO']} w/\n  #{Rack::Request.new(env).params.inspect}\n#{'^'*40}"
      @app.call(env)
    end

  end
end