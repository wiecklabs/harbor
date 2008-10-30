module Wheels
  class Router

    URI_CHAR = '[^/?:,&#\.]'.freeze unless defined?(URI_CHAR)
    PARAM = /(:(#{URI_CHAR}+))/.freeze unless defined?(PARAM)

    attr_accessor :routes

    def initialize(&routes)
      @routes = []
      @route_match_cache = {}
      instance_eval(&routes) if block_given?
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

    def using(klass, &block)
      Using.new(self, klass).instance_eval(&block)
    end

    class Using
      def initialize(router, klass)
        @router = router
        @klass = klass
      end

      %w(get post put delete).each do |verb|
        class_eval <<-EOF
        def #{verb}(matcher, &handler)
          block = lambda do |request, response|
            object = @klass.new(request, response)
            handler.arity == 2 ? handler[object, request.params] : handler[object]
          end
          @router.send(#{verb.inspect}, matcher, &block)
        end
        EOF
      end
    end

    def register(request_method, matcher, &handler)
      @routes << [request_method.to_s.upcase, transform(matcher), handler]
    end

    def clear
      @routes = []
    end

    def match(request)
      @routes.each do |request_method, matcher, handler|
        next unless request.request_method == request_method
        next unless matcher.call(request)
        return handler
      end

      # No routes matched, so return false
      false
    end

    private

    def transform(matcher)
      case matcher
      when Proc then matcher
      when Regexp then lambda { |request| request.path_info =~ matcher }
      when Array
        regex = matcher.shift
        generate_param_matcher(regex, matcher)
      when String
        param_keys = []
        regex = matcher.gsub(PARAM) { param_keys << $2; "(#{URI_CHAR}+)" }
        regex = /^#{regex}$/
        generate_param_matcher(regex, param_keys)
      end
    end

    def generate_param_matcher(regex, param_keys)
      lambda do |request|
        if request.path_info =~ regex
          request.params.update(Hash[*param_keys.zip($~.captures).flatten])
        end
      end
    end

  end
end