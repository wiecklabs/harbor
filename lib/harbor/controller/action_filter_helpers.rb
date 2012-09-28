class Harbor
  class Controller
    ##
    # Provides a way to register code to be run before or after controller actions.
    #
    # Although it supports registering filter to a path that looks like a "global"
    # route, it will only be applied to requests that get mapped to the defining
    # controller.
    #
    #   class PostsController < Harbor::Controller
    #     # Runs block before any incoming request
    #     before :all do
    #       # ...
    #     end
    #
    #     # Calls "log" instance method before any incoming PUT request
    #     after :all, :request_method => :put, :call => :log
    #
    #     # Checks for authentication on all admin requests to this controller
    #     before '/admin/*', :call => :check_authentication
    #
    #     # Checks for authorization before updating or creating a new post
    #     before ':id', :request_method => [:put, :post], :call => :check_authorization
    #   end
    #
    # TODO: Make it "inheritable"
    ##
    module ActionFilterHelpers
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def before(*args, &block)
          filters[:before] << ActionFilter.new(self, *args, &block)
        end

        def after(*args, &block)
          filters[:after] << ActionFilter.new(self, *args, &block)
        end

        def filters
          @filters ||= {:before => [], :after => []}
        end
      end

      def filter!(type)
        self.class::filters[type].each do |action_filter|
          action_filter.filter! self
        end
      end
    end
  end
end
