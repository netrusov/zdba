# frozen_string_literal: true

module ZDBA
  module LogFormatters
    class Base < ::Logger::Formatter
      def initialize(...)
        super
        initialize_context_state_key
      end

      def initialize_copy(...)
        super
        initialize_context_state_key
      end

      def current_context
        ::Thread.current[@context_state_key] ||= {}
      end

      def set_context(context)
        current_context.merge!(context)
      end

      def with_context(context)
        set_context(context)

        begin
          yield
        ensure
          context.each_key do |key|
            current_context.delete(key)
          end
        end
      end

      private

      def initialize_context_state_key
        @context_state_key = "zdba_logger_context:#{object_id}"
      end
    end
  end
end
