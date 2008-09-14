require "rack/request"

module Rack
  class Request
    def request_method
      @env['REQUEST_METHOD'] = params['_method'].upcase if request_method_in_params?
      @env['REQUEST_METHOD']
    end

    private
    def request_method_in_params?
      @env["REQUEST_METHOD"] == "POST" && %w(PUT DELETE).include?((params['_method'] || "").upcase)
    end
  end
end
