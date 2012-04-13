class Harbor
  class Controller
    class ActionFilter
      def initialize(controller_class, path, options = {}, &block)
        options = path if path.is_a? Hash

        @block      = block ? block : create_block(options.delete(:call))
        @conditions = normalize_conditions(options)
        @path       = normalize_path(controller_class, path)
      end

      def filter!(controller)
        controller.instance_eval &@block if applies_to?(controller.request)
      end

      private

      def applies_to?(request)
        (@path == :all || request.path_info =~ @path) &&
          (@conditions[:request_method] == :all || @conditions[:request_method].include?(request.request_method))
      end

      def normalize_conditions(options)
        request_method = options[:request_method]
        request_method = :all unless request_method && request_method != []

        if request_method != :all
          request_method = [request_method] unless options[:request_method].is_a? Array
          request_method.map!{|m| m.to_s.upcase}
        end
        options[:request_method] = request_method

        options
      end

      def normalize_path(controller_class, path)
        return :all if path == :all

        regex_parts = NormalizedPath.new(controller_class, path).split('/')

        return /^\/$/ if regex_parts.empty?

        if Router::Route::wildcard_token? regex_parts.last
          regex_parts[-1] = '[^/]+'
        elsif Router::RouteNode::wildcard_fragment? regex_parts.last
          regex_parts[-1] = '.*'
        end

        Regexp.new "^/#{regex_parts.join('/')}$"
      end

      def create_block(method)
        Proc.new { self.send(method) }
      end
    end
  end
end
