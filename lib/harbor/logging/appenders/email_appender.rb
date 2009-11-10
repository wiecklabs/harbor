module Harbor
  module LogAppenders

    class EmailAppender < Logging::Appender
      def initialize(container, from, *addresses)
        @container = container
        @from = from
        @addresses = addresses

        super("exception_notifier", :level => :error)
      end

      def write(event)
        unless @level > event.level
          mailer = @container.get(:mailer)
          mailer.from = @from
          mailer.to = @addresses

          data = event.data
          subject = data.split($/, 2)[0]
          data << "\n(from: #{`hostname`.chomp}, PID: #{Process.pid})"

          mailer.subject = "[ERROR] #{subject}"
          mailer.text = data
          mailer.send!
        end
      end
    end

  end
end