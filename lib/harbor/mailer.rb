require "cgi"

gem "mail_builder"
require "mail_builder"

require Pathname(__FILE__).dirname + "mail_servers/abstract"
require Pathname(__FILE__).dirname + "mail_servers/sendmail"
require Pathname(__FILE__).dirname + "mail_servers/smtp"
require Pathname(__FILE__).dirname + "mail_servers/test"

module Harbor
  class Mailer < MailBuilder

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

    def tokenize_urls!(mail_server_url)
      mail_server_url = "http://#{mail_server_url}" unless mail_server_url =~ /^http/

      [:@html, :@text].each do |ivar|
        if content = instance_variable_get(ivar)
          new_content = content.to_s.gsub(/(https?:\/\/.+?(?=[" <]|$))(\W*)(.{4}|$)/) do |url|
            # Don't tokenize the inner text of a link
            $3 == '</a>' ? url : ("#{mail_server_url}/.m/#{envelope_id}?r=#{CGI.escape([$1].pack("m"))}" + $2 + $3)
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