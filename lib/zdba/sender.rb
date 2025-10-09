# frozen_string_literal: true

module ZDBA
  class Sender
    ZABBIX_HEADER = "ZBXD\x01"

    def initialize(name:, config:, queue:, checker:)
      @name = name
      @config = config
      @queue = queue
      @checker = checker
    end

    def run
      ::ZDBA.logger.info { "sender[#{@name}]: starting" }

      while @checker.call || !@queue.empty?
        unless @checker.call
          ::ZDBA.logger.info { "sender[#{@name}] (stopping): queue still contains #{@queue.size} message(s)" }
        end

        data = []

        @config[:batch_size].times do
          data << @queue.pop(true)
        rescue ::ThreadError
          break
        end

        unless data.empty?
          ::ZDBA.logger.debug { data.inspect }
          # send_data(data)
        end

        sleep(1)
      end

      ::ZDBA.logger.info { "sender[#{@name}]: shutdown" }
    end

    private

    def send_data(data)
      payload = ::JSON.dump({ request: 'sender data', data: })
      header = ::ZDBA::Sender::ZABBIX_HEADER + [payload.bytesize].pack('Q<')
      message = header + payload

      uri = ::URI.parse(@config[:url])

      begin
        ::Socket.tcp(uri.host, uri.port, connect_timeout: @config[:connect_timeout]) do |sock|
          sock.write(message)

          response_header = sock.read(13)
          unless response_header&.start_with?(::ZDBA::Sender::ZABBIX_HEADER)
            raise("Invalid response header: #{response_header.inspect}")
          end

          response_length = response_header.byteslice(5, 8).unpack1('Q<')
          response_body = sock.read(response_length)

          ::ZDBA.logger.debug { "sender[#{@name}]: response #{response_body}" }
        end
      rescue ::StandardError => e
        ::ZDBA.logger.error { "sender[#{@name}]: failed to send data: #{e.message}" }
      end
    end

    def send_data_with_retry(data)
      max_retries = @config.fetch(:max_retries, 5)
      base_delay = @config.fetch(:retry_delay, 1.0)
      max_delay = @config.fetch(:max_retry_delay, 30.0)

      attempts = 0

      begin
        send_data(data)
        true
      rescue ::StandardError => e
        attempts += 1

        if attempts > max_retries
          ::ZDBA.logger.error { "sender[#{@name}]: giving up after #{attempts} attempts: #{e.message}" }
          false
        else
          delay = [base_delay * (2**(attempts - 1)), max_delay].min
          ::ZDBA.logger.warn { "sender[#{@name}]: retrying in #{delay}s (attempt #{attempts}) - #{e.message}" }
          sleep(delay)
          retry
        end
      end
    end
  end
end
