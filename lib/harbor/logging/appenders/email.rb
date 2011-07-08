module Harbor
  module LogAppenders

    class Email < Logging::Appender

      attr_accessor :duplicate_subject_delivery_threshold

      def initialize(container, from, *addresses)
        @container = container
        @from = from
        @addresses = addresses
        @tracked_subjects = []

        # Deliver emails with exact-match subjects only every 10 Minutes
        @duplicate_subject_delivery_threshold = 60 * 10

        super("exception_notifier", :level => :error)
      end

      def write(event)
        return unless event.level >= @level

        flush_expired_subjects

        data = event.data
        subject = data.split($/, 2)[0]

        if tracked_subject = @tracked_subjects.detect { |tracked_subject| tracked_subject.subject == subject }
          tracked_subject.occurances << Time.now

          # Don't send the email if we've already sent one within the time threshold
          return false if (Time.now - tracked_subject.sent_at) < @duplicate_subject_delivery_threshold
        else
          tracked_subject = TrackedSubject.new(subject)
          tracked_subject.occurances << Time.now

          @tracked_subjects << tracked_subject
        end

        mailer = @container.get(:mailer)
        mailer.from = @from
        mailer.to = @addresses
        host = `hostname`.chomp

        data << "\n(from: #{host}, PID: #{Process.pid})"

        mailer.subject = "[ERROR] [#{host}] #{subject}"
        mailer["x_priority"] = "1 (Highest)"
        mailer["x_msmail_priority"] = "High"
        mailer.text = if tracked_subject.occurances.size > 1
          "Repeated #{tracked_subject.occurances.size} times since #{tracked_subject.sent_at.strftime('%Y-%m-%d %R%z')}\n\n#{data}"
        else
          data
        end
        mailer.send!

        tracked_subject.occurances.clear
        tracked_subject.sent_at = Time.now
      end

      private

      ##
      # Flushes items from the @tracked_subjects array when they are no longer useful
      ##
      def flush_expired_subjects
        @tracked_subjects.reject! do |tracked_subject|
          tracked_subject.occurances.empty? && (Time.now - tracked_subject.sent_at) >= @duplicate_subject_delivery_threshold
        end
      end
    end


    class Email::TrackedSubject
      attr_accessor :sent_at
      attr_reader :subject, :occurances

      def initialize(subject)
        @subject = subject
        @occurances = []
      end
    end

  end
end