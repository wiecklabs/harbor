require 'open3'

module Harbor
  module Mail
    module Servers
      class Sendmail < Abstract

        attr_accessor :filter

        def initialize(config = {})
          @sendmail = config[:sendmail] || `which sendmail`.chomp
          @filter = config[:delivery_address_filter]
          @sender = config[:sender] || "bounce"
        end

        def deliver(message_or_messages)
          messages = Array === message_or_messages ? message_or_messages : [message_or_messages]
        
        
          messages.each do |message|
            filter.apply(message) if filter
          
            Open3.popen3("#{@sendmail} -i -t -f#{@sender}") do |stdin, stdout, stderr|
              stdin.write(message.to_s)
            end
          
          end
        end
      end
    end
  end
end