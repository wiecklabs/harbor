class Router

  URI_CHAR = '[^/?:,&#\.]'.freeze unless defined?(URI_CHAR)
  PARAM = /(:(#{URI_CHAR}+)|\*)/.freeze unless defined?(PARAM)

  attr_accessor :routes

  def initialize
    @routes = []
  end

  def get(matcher, &handler)
    register(:get, matcher, &handler)
  end

  def register(request_method, matcher, &handler)
    @routes << [request_method.to_s.upcase, transform(matcher), handler]
  end

  def match(request)
    @routes.each do |request_method, matcher, handler|
      break handler if request.request_method == request_method && matcher.call(request)
    end
  end

  private

  def transform(matcher)
    case matcher
    when Proc then matcher
    when Regexp then lambda { |request| request.path_info =~ matcher }
    end
  end

end