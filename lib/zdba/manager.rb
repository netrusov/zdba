# frozen_string_literal: true

module ZDBA
  class Manager
    JOIN_TIMEOUT = 5

    def initialize(config)
      @config = config
    end

    def run
      ZDBA.logger.info { format('starting ZDBA v%s', ZDBA::VERSION) }

      running = true
      queue = Thread::Queue.new

      Signal.trap('INT')  { running = false }
      Signal.trap('TERM') { running = false }

      checker = -> { running }

      worker_threads = @config[:databases].map do |worker_config|
        Thread.new do
          Thread.current.name = "worker-#{worker_config[:name]}"

          ZDBA::Worker.new(
            name: worker_config[:name],
            config: worker_config,
            queue:,
            checker:
          ).run
        end
      end

      sender_threads = Array.new(@config[:sender][:threads]) do |i|
        Thread.new do
          Thread.current.name = "sender-#{i}"

          ZDBA::Sender.new(
            name: i,
            config: @config[:sender],
            queue:,
            checker:
          ).run
        end
      end

      sleep(1) while running

      ZDBA.logger.info { 'stopping' }

      (worker_threads + sender_threads).each do |thread|
        next if thread.join(JOIN_TIMEOUT)

        ZDBA.logger.warn { "thread '#{thread.name}' did not stop within #{JOIN_TIMEOUT}s" }
      end
    end
  end
end
