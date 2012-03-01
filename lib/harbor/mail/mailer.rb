require "cgi"

require_relative "builder"

require_relative "servers/abstract"
require_relative "servers/sendmail"
require_relative "servers/smtp"
require_relative "servers/test"
require_relative "filters/delivery_address_filter"

module Harbor
  module Mail
    class Mailer < Builder

      def self.layout=(layout)
        @@layout = layout
      end

      def self.layout
        @@layout rescue nil
      end

      def self.host=(host)
        @@host = host
      end

      def self.host
        @@host rescue "www.example.com"
      end

      attr_accessor :mail_server

      def initialize(*args)
        super

        @layout = self.class.layout
        @host = self.class.host
      end

      ##
      # We want to automatically assign the value of @mailer to self whenever
      # a view is passed to the mailer object. This lets us use, for instance,
      # the envelope_id to track click-through's and bounces using the same
      # identifier.
      #
      %w(html= text=).each do |method|
        define_method(method) do |value|
          if value.is_a?(Harbor::View)
            value.context.merge(:mailer => self)
          end

          if @layout && layout = @layout.dup
            layout.sub!(/(\.html\.erb$)|$/, ".txt.erb") if method == "text="
            value = Harbor::View.new(layout, :content => value, :mailer => self)
          end

          super(value)
        end
      end

      def host
        @host
      end

      ##
      # Tokenizes urls in the email body by replacing them with the mail_server_url
      # provided. The message's envelope_id and a base64 encoded version of the original
      # url are passed to the URL provided.
      #
      #   mailer.html = 'Please visit <a href="http://example.com">our site</a> for details.'
      #   mailer.tokenize_urls!("http://example.com/.m/%s?redirect=%s")
      #   mailer.html # => "Please visit <a href=\"http://example.com/.m/%2AF%2Ch2Gtn.ny1poJnnvvCeSMZA?redirect=aHR0cDovL2V4YW1wbGUuY29t%0A\">our site</a> for details."
      ##
      def tokenize_urls!(mail_server_url)
        mail_server_url = "http://#{mail_server_url}" unless mail_server_url =~ /^http/

        [:@html, :@text].each do |ivar|
          if content = instance_variable_get(ivar)
            new_content = content.to_s.gsub(/(https?:\/\/[^<"\s\n]+)(.{4}|$)/m) do |url|
              # Don't tokenize the inner text of a link
              if $2 == '</a>'
                url
              else
                (mail_server_url % [CGI.escape(envelope_id), CGI.escape([$1].pack("m"))]) + $2
              end
            end
            instance_variable_set(ivar, new_content)
          end
        end
      end

      def send!
        mail_server.deliver(self)
      end

    end
  end
end
