require 'mail'

module Harbor
  module MailServers
    class Sendgrid < Abstract
      def initialize(config = {})
        missing_keys = []
        [:user_name, :password, :domain].each do |required_key|
          missing_keys << required_key unless config.keys.include? required_key
        end

        # TODO: Add ArgumentError class.
        raise "ArgumentError: You must provide :#{missing_keys.join(",:")} in the Sendgrid config." if missing_keys.any?

        config[:delivery_method] ||= :smtp
        config[:address] ||= 'smtp.sendgrid.net'
        config[:port] ||= 587
        config[:authentication] ||= 'plain'
        config[:enable_starttls_auto] ||= true

        Mail.defaults do
          delivery_method config[:delivery_method].to_sym, { :address => config[:address].to_s,
            :port => config[:port].to_i,
            :domain => config[:domain].to_s,
            :user_name => config[:user_name].to_s,
            :password => config[:password].to_s,
            :authentication => config[:authentication].to_s,
            :enable_starttls_auto => config[:enable_starttls_auto] == true }
        end
      end

      def deliver(mailer)
        raise "ArgumentError: #{mailer.class} must be of type Harbor::Mailer" unless mailer.is_a? Harbor::Mailer

        Mail.deliver do
          to mailer.to

          from mailer.from

          subject mailer.subject

          text_part do
            body mailer.text
          end

          html_part do
            body mailer.html
          end

          mailer.attachments.each do |attachment|
            add_file( :filename => attachment.name, :content => File.read( attachment.file ), :type => attachment.type )
          end
        end
      end
    end
  end
end
