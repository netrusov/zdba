# frozen_string_literal: true

module ZDBA
  class Manager
    JOIN_TIMEOUT = 5

    def initialize(config)
      @config = config

      @logger = ::ZDBA.logger
    end

    def run
      @logger.info { format('starting ZDBA v%s', ::ZDBA::VERSION) }

      queue = ::Thread::Queue.new
      running = true
      running_checker = -> { running }

      ::Signal.trap('INT')  { running = false }
      ::Signal.trap('TERM') { running = false }

      worker_threads = @config[:databases].map do |config|
        ::Thread.new do
          name = "worker-#{config[:name]}"

          ::Thread.current.name = name

          ::ZDBA::Worker.new(
            name:,
            config:,
            queue:,
            running_checker:
          ).run
        end
      end

      sender_threads = ::Array.new(@config[:sender][:threads]) do |i|
        ::Thread.new do
          name = "sender-#{i}"

          ::Thread.current.name = name

          ::ZDBA::Sender.new(
            name:,
            config: @config[:sender],
            queue:,
            running_checker:
          ).run
        end
      end

      sleep(1) while running

      @logger.info { 'stopping' }

      (worker_threads + sender_threads).each do |thread|
        next if thread.join(::ZDBA::Manager::JOIN_TIMEOUT)

        @logger.warn { "thread '#{thread.name}' did not stop within #{::ZDBA::Manager::JOIN_TIMEOUT}s" }
      end
    end
  end
end
