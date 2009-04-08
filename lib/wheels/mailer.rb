require "cgi"
require "mailfactory"

require Pathname(__FILE__).dirname + "mail_servers/abstract"
require Pathname(__FILE__).dirname + "mail_servers/sendmail"
require Pathname(__FILE__).dirname + "mail_servers/smtp"

module Wheels
  class Mailer < MailFactory

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

        if self.class.layout && layout = self.class.layout.dup
          layout.sub!(/(\.html\.erb$)|$/, ".txt.erb") if method == "text="
          value = Wheels::View.new(layout, :content => value)
        end

        super(value)
      end
    end

    def text
      @text
    end

    def html
      @html
    end

    def host
      self.class.host
    end

    def tokenize_urls!(mail_server_url)
      mail_server_url = "http://#{mail_server_url}" unless mail_server_url =~ /^http/

      [:@html, :@text].each do |ivar|
        if content = instance_variable_get(ivar)
          new_content = content.to_s.gsub(/(http(s)?:\/\/.+?(?=[" <]|$))/) do |url|
            "#{mail_server_url}/m/#{envelope_id}?r=#{CGI.escape([url].pack("m"))}"
          end
          instance_variable_set(ivar, new_content)
        end
      end
    end

    def send!
      mail_server.deliver(self)
    end

    ##
    # Remove code duplication from mailfactory's add_attachment method,
    # so that we can over-ride add_attachment_as to work lazily.
    ##

    alias :mailfactory_add_attachment :add_attachment
    alias :mailfactory_add_attachment_as :add_attachment_as

    def add_attachment(filename, type = nil, attachment_headers = nil)
      add_attachment_as(filename, Pathname.new(filename).basename, type, attachment_headers)
    end

    alias :attach :add_attachment

    def add_attachment_as(file, email_filename, type = nil, attachment_headers = nil)
      attachment = {}
      attachment['filename'] = email_filename
      attachment['attachment'] = Attachment.new(file)

      # taken from MailFactory#add_attachment_as
      if(type != nil)
        attachment['mimetype'] = type.to_s()
      elsif(file.kind_of?(String) or file.kind_of?(Pathname))
        attachment['mimetype'] = MIME::Types.type_for(file.to_s()).to_s
      else
        attachment['mimetype'] = ''
      end

      # taken from MailFactory#add_attachment_as
      if(attachmentheaders != nil)
        if(!attachmentheaders.kind_of?(Array))
          attachmentheaders = attachmentheaders.split(/\r?\n/)
        end
        attachment['headers'] = attachmentheaders
      end

      @attachments << attachment
    end

    alias :attach_as :add_attachment_as

    class Attachment
      attr_accessor :file, :body

      def initialize(file)
        @file = file

        # If we have a File/IO object, read it. Otherwise, we'll read it lazily.
        @body = file.read() if !file.kind_of?(Pathname) && file.respond_to?(:read)
      end

      def to_s
        @body ||= ::File.open(file.to_s(), "rb") { |f| f.read() }
        [@body].pack("m")
      end

      def inspect
        "#<Wheels::Mail::Attachment @file=#{file.inspect}>"
      end
    end

  end
end