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

  def register(request_method, matcher, &handler)
    @routes << [request_method.to_s.upcase, transform(matcher), handler]
  end

  def clear
    @routes = []
  end

  def match(request)
    # TODO: this cache key probably needs to be beefed up
    @route_match_cache["#{request.request_method}_#{request.path_info}"] ||= (route = @routes.detect do |request_method, matcher, handler|
      next unless request.request_method == request_method
      next unless matcher.call(request)
      handler
    end ) ? route[2] : false
  end

  private

  def transform(matcher)
    case matcher
    when Proc then matcher
    when Regexp then lambda { |request| request.path_info =~ matcher }
    when Array
      regex = matcher.shift
      lambda do |request|
        if request.path_info =~ regex
          request.params.update(Hash[*matcher.zip($~.captures).flatten])
        end
      end
    when String
      param_keys = []
      regex = matcher.gsub(PARAM) { param_keys << $2; "(#{URI_CHAR}+)" }
      regex = /^#{regex}$/
      lambda do |request|
        if request.path_info =~ regex
          request.params.update(Hash[*param_keys.zip($~.captures).flatten])
        end
      end
    end
  end

end