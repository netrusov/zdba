# frozen_string_literal: true

module ZDBA
  class Manager
    JOIN_TIMEOUT = 5

    def initialize(config)
      @config = config

      @logger = ::ZDBA.logger.with_context(service: 'manager')
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
          ::Thread.current.name = "worker<#{config[:name]}>"

          ::ZDBA::Worker.new(
            config:,
            queue:,
            running_checker:,
            logger: @logger.with_context(service: 'worker', instance: config[:name])
          ).run
        end
      end

      sender_threads = ::Array.new(@config[:sender][:threads]) do |i|
        ::Thread.new do
          ::Thread.current.name = "sender<#{i}>"

          ::ZDBA::Sender.new(
            config: @config[:sender],
            queue:,
            running_checker:,
            logger: @logger.with_context(service: 'sender', instance: i.to_s)
          ).run
        end
      end

      sleep(1) while running

      @logger.info { 'stopping threads' }

      (worker_threads + sender_threads).each do |thread|
        next if thread.join(::ZDBA::Manager::JOIN_TIMEOUT)

        @logger.warn { "thread `#{thread.name}` did not stop within #{::ZDBA::Manager::JOIN_TIMEOUT}s, executing force shutdown" }

        thread.exit
      end

      @logger.info { 'exiting' }
    end
  end
end
