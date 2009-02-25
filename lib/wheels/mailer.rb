require "cgi"
require "mailfactory"

require Pathname(__FILE__).dirname + "mail_servers/abstract"
require Pathname(__FILE__).dirname + "mail_servers/sendmail"
require Pathname(__FILE__).dirname + "mail_servers/smtp"

module Wheels
  class Mailer < MailFactory

    attr_accessor :mail_server

    ##
    # MailFactory by default generates the attachment and body boundaries
    # on initialize, which is rather slow when you're creating a lot of
    # mailer objects in a loop.
    # 
    # This patch offloads the cost of generating the boundaries to the construct
    # method (which is called by to_s()), so this more expensive operation
    # can occure on the mail server side.
    #
    def initialize
      @headers = Array.new()
      @attachments = Array.new()
      @html = nil
      @text = nil
      @charset = 'utf-8'
    end

    def construct(*args)
      @attachmentboundary ||= generate_boundary()
      @bodyboundary ||= generate_boundary()
      super
    end

    def envelope_id
      @envelope_id ||= `uuidgen`.chomp
    end

    ##
    # For displaying emails in an interface, we want to store the
    # subject before it has been encoded for delivery.
    # 
    def subject=(subject)
      @subject = subject
      super
    end

    def subject
      @subject
    end

    ##
    # We ensure that the envelope id for this message gets set when the message
    # is contructed. We remove any existing Mail-From headers.
    # 
    def headers_to_s
      remove_header("Mail-From")
      @headers.unshift("Mail-From: #{`whoami`.chomp}@#{`hostname`.chomp} ENVID=#{envelope_id}")
      super
    end

    ##
    # We want to automatically assign the value of @mailer to self whenever
    # a view is passed to the mailer object. This lets us use, for instance,
    # the envelope_id to track click-through's and bounces using the same
    # identifier.
    # 
    %w(html= rawhtml= text=).each do |method|
      define_method(method) do |value|
        if value.is_a?(Wheels::View)
          value.context.merge(:mailer => self)
        end
        super
      end
    end

    def text
      @text
    end

    def html
      @html
    end

    def tokenize_urls!(mail_server_url)
      mail_server_url = "http://#{mail_server_url}" unless mail_server_url =~ /^http/

      [:@html, :@text].each do |ivar|
        if content = instance_variable_get(ivar)
          new_content = content.to_s.gsub(/(http(s)?:\/\/.+?)(?=[" ]|$)/) do |url|
            "#{mail_server_url}/m/#{envelope_id}?r=#{CGI.escape([url].pack("m"))}"
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