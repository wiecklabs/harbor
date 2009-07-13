module Harbor
  class Router

    URI_CHAR = '[^/?:,&#\.\[\]]'.freeze unless defined?(URI_CHAR)
    PARAM = /(:(#{URI_CHAR}+))/.freeze unless defined?(PARAM)

    attr_accessor :routes

    def initialize(&routes)
      @routes = []
      @route_match_cache = {}
      instance_eval(&routes) if block_given?
    end

    def merge!(other)
      self.routes |= other.routes
    end

    # Matches a GET request
    def get(matcher, &handler)
      register(:get, matcher, &handler)
    end

    # Matches a POST (create) request
    def post(matcher, &handler)
      register(:post, matcher, &handler)
    end

    # Matches a PUT (update) request
    def put(matcher, &handler)
      register(:put, matcher, &handler)
    end

    # Matches a DELETE request
    def delete(matcher, &handler)
      register(:delete, matcher, &handler)
    end

    def using(container, klass, initializer = nil, &block)
      Using.new(self, container, klass, initializer).instance_eval(&block)
    end

    class Using
      def initialize(router, container, klass, initializer)
        @router = router
        @container = container

        if klass.is_a?(String)
          @service_name = klass
        else
          @service_name = klass.to_s
          @container.register(@service_name, klass, &initializer)
        end
      end

      %w(get post put delete).each do |verb|
        class_eval <<-EOS
        def #{verb}(matcher, &handler)
          @router.send(#{verb.inspect}, matcher) do |request, response|
            service = @container.get(@service_name, :request => request, :response => response)

            # TODO: Eh? Why wouldn't you just register the Logger with the container?
            service.logger = Logging::Logger[service] if service.respond_to?(:logger=)

            handler.arity == 2 ? handler[service, request] : handler[service]
          end
        end
        EOS
      end
    end

    def register(request_method, matcher, &handler)
      matcher, param_keys = transform(matcher)
      route = [request_method.to_s.upcase, matcher, param_keys, handler]
      @routes << route
      route
    end

    def clear
      @routes = []
    end

    def match(request)
      @routes.each do |request_method, matcher, param_keys, handler|
        next unless request.request_method == request_method

        # Strip trailing forward-slash on request path before matching
        request_path = (request.path_info[-1] == ?/) ? request.path_info[0..-2] : request.path_info

        next unless request_path =~ matcher

        request.params.update(Hash[*param_keys.zip($~.captures).flatten])
        return handler
      end

      # No routes matched, so return false
      false
    end

    private

    def transform(matcher)
      param_keys = []

      if matcher.is_a?(String)
        # Strip trailing forward-slash on routes
        matcher = matcher[0..-2] if (matcher[-1] == ?/)
        matcher = /^#{matcher.gsub('.', '[\.]').gsub(PARAM) { param_keys << $2; "(#{URI_CHAR}+)" }}$/
      end

      [matcher, param_keys]
    end

  end
end