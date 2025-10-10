# frozen_string_literal: true

module ZDBA
  module LogFormatters
    class JSON < ::ZDBA::LogFormatters::Base
      def call(severity, timestamp, _progname, message)
        message, context = message

        data = {
          severity:,
          timestamp:,
          # caller: caller(4..4)[0],
          message: msg2str(message)
        }

        if (e = context&.delete(:exception))
          data[:exception] = {
            class: e.class,
            message: e.message,
            backtrace: e.backtrace
          }
        end

        add_context(data, current_context)
        add_context(data, context)

        ::JSON.dump(data).concat("\n")
      end

      private

      def add_context(data, context)
        return if context.nil? || context.empty?

        data.merge!(context)
      end
    end
  end
end
