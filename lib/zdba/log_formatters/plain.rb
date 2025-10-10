# frozen_string_literal: true

module ZDBA
  module LogFormatters
    class Plain < ::ZDBA::LogFormatters::Base
      def call(severity, timestamp, progname, message)
        message, context = message

        exception = format_exception(context&.delete(:exception))

        message = msg2str(message)
        message = add_context(message, context)
        message = add_context(message, current_context)
        message = "#{message}#{exception}" if exception

        super
      end

      private

      def add_context(message, context)
        return message if context.nil? || context.empty?

        text = +''

        context.each do |key, value|
          text << "[#{key}:#{value.nil? ? 'nil' : value}] "
        end

        "#{text}#{message}"
      end

      def format_exception(e)
        return unless e

        text = "\n#{e.backtrace.first}: #{e.message} (#{e.class})"
        text << "\n\t#{e.backtrace[1..].join("\n\t")}" if e.backtrace.size > 1

        text
      end
    end
  end
end
