class Harbor
  class Router
    module Descriptor
      def self.collect_routes
        routes = []
        router.verbs.each do |verb, router|
          router.static_routes.each do |path, route|
            path = "/#{path.join('/')}"
            routes << {path: path, verb: verb, controller: route.action.controller}
          end

          router.build!
          _collect_routes(verb, routes, router.root)
        end
        routes.sort{|a, b| a[:path] <=> b[:path]}
      end

      private

      def self.router
        Harbor::Router::instance
      end

      def self._collect_routes(verb, routes, node)
        return unless node

        if node.is_a? Harbor::Router::WildcardNode
          _collect_routes(verb, routes, node.wildcard_tree)
          node.trees.values.each do |node|
            _collect_routes(verb, routes, node)
          end
        else
          if node.action
            routes << {path: "/" + node.tokens.join('/'), verb: verb, controller: node.action.controller}
          end

          _collect_routes(verb, routes, node.left)
          _collect_routes(verb, routes, node.match)
          _collect_routes(verb, routes, node.right)
        end
      end
    end
  end
end
