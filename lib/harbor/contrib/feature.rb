class Harbor
  module Contrib
    ##
    # Convenience class for bundling optional features in Harbor applications.
    # 
    #   class MyApplication::Features::Feature < Harbor::Contrib::Feature
    #     class << self
    #       attr_accessor :option
    #     end
    # 
    #     def self.enable
    #       if enabled = super
    #         require "necessary/files"
    #       end
    #       
    #       enabled
    #     end
    #   end
    # 
    #   MyApplication::Feature::Feature.enable do |feature|
    #     feature.option = true
    #   end
    # 
    # It can also be helpful to utilize Harbor::Router#merge! to bundle routes with
    # the feature.
    # 
    #   class MyApplication::Features::Feature
    #     def self.routes(services)
    #       Harbor::Router.new do
    #         get("/feature") { |request, response| response.puts "Inside feature" }
    #       end
    #     end
    #   end
    # 
    #   class MyApplication
    #     def self.routes(services)
    #       Harbor::Router.new do
    #         get("/") { |request, response| response.puts "Inside MyApplication" }
    #         merge!(Features::Feature.routes(services)) if Features::Feature.enabled?
    #       end
    #     end
    #   end
    # 
    ##
    class Feature
      def self.enable
        return false if @enabled
        @enabled = true

        yield self if block_given?

        @enabled
      end

      def self.enabled?
        !!@enabled
      end
    end
  end
end