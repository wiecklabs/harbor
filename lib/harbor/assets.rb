require 'sprockets'

class Harbor
  class Assets
    extend Forwardable

    attr_reader :compile, :paths
    attr_accessor :mount_path

    def initialize(sprockets_env = Sprockets::Environment.new)
      @paths = []
      @mount_path = 'assets'
      @sprockets_env = sprockets_env
    end

    def compile=(compile)
      @compile = compile

      if @compile
        cascade << self
      else
        cascade.unregister(self)
      end
    end

    def match(request)
      return unless compile
    end

    def call(request, response)
    end

    private

    def cascade
      @cascade ||= Harbor::Dispatcher.instance.cascade
    end
  end
end
