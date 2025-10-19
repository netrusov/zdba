# frozen_string_literal: true

module ZDBA
  class Sender
    ZABBIX_HEADER = "ZBXD\x01"

    def initialize(config:, queue:, running_checker:, logger: ::ZDBA.logger)
      @config = config
      @queue = queue
      @running_checker = running_checker
      @logger = logger

      @zabbix_uri = ::URI.parse(@config[:url])
    end

    def run
      @logger.info { 'starting' }

      while @running_checker.call || !@queue.empty?
        @logger.info { "(stopping): queue still contains #{@queue.size} item(s)" } unless @running_checker.call

        data = []

        @config[:batch_size].times do
          data << @queue.pop(true)
        rescue ::ThreadError
          break
        end

        unless data.empty?
          @logger.with_context(batch_id: ::SecureRandom.uuid) do
            send_data_with_retry(data)
          end
        end

        sleep(1)
      end

      @logger.info { 'exiting' }
    end

    private

    def send_data_with_retry(data)
      message = prepare_message(data)

      retry_count = @config.dig(:retry, :count)
      retry_delay = @config.dig(:retry, :delay)
      retry_max_delay = @config.dig(:retry, :max_delay)
      retry_attempts = 0

      @logger.debug { "sending #{data.size} item(s) to Zabbix: #{data.inspect}" }

      begin
        send_message(message)

        @logger.info { 'connection to Zabbix re-established' } if retry_attempts.positive?

        true
      rescue ::StandardError => e
        @logger.error { ['failed to send data to Zabbix', { exception: e }] }

        if retry_attempts >= retry_count
          @logger.error { "giving up after #{retry_attempts} attempts" }

          false
        else
          retry_attempts += 1
          delay = [retry_delay * (2**(retry_attempts - 1)), retry_max_delay].min

          @logger.warn { "retrying in #{delay}s (attempt #{retry_attempts}/#{retry_count})" }

          sleep(delay)
          retry
        end
      end
    end

    def prepare_message(data)
      payload = ::JSON.dump({ request: 'sender data', data: })
      header = ::ZDBA::Sender::ZABBIX_HEADER + [payload.bytesize].pack('Q<')

      header + payload
    end

    def send_message(message)
      ::Socket.tcp(@zabbix_uri.host, @zabbix_uri.port, connect_timeout: @config[:connect_timeout]) do |sock|
        sock.write(message)

        response_header = sock.read(13)

        unless response_header&.start_with?(::ZDBA::Sender::ZABBIX_HEADER)
          raise("invalid response header: #{response_header.inspect}")
        end

        @logger.debug do
          response_length = response_header.byteslice(5, 8).unpack1('Q<')
          response_body = sock.read(response_length)

          "data sent successfully: #{response_body}"
        end
      end
    end
  end
end
