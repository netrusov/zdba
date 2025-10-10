# frozen_string_literal: true

module ZDBA
  class Logger < ::Logger
    def with_context(context)
      if defined?(yield)
        formatter.with_context(context) { yield(self) }
      else
        logger = clone
        logger.formatter = formatter.clone
        logger.formatter.set_context(formatter.current_context)
        logger.formatter.set_context(context)
        logger
      end
    end

    def set_context(context)
      formatter.set_context(context)
    end
  end
end
