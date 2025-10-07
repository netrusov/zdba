# frozen_string_literal: true

module ZDBA
  class Worker
    DISCOVERY_RULE_KEY_FORMAT = '{#%s}'
    DISCOVERY_ITEM_KEY_FORMAT = '%s[%s]'

    def initialize(name:, config:, queue:, checker:)
      @name = name
      @config = config
      @queue = queue
      @checker = checker
      @last_polls = {}

      @connection = ZDBA::Connection.new(@config[:connection])
    end

    def run
      ZDBA.logger.info { "worker[#{@name}]: starting" }

      while @checker.call
        collect_metrics

        sleep(1)
      end

      ZDBA.logger.info { "worker[#{@name}]: shutdown" }
    ensure
      @connection.disconnect
    end

    private

    def collect_metrics
      @config[:items]&.each do |item|
        case item[:type]
        when 'discovery_rule'
          process_discovery_rule(item)
        when 'discovery_item'
          process_discovery_item(item)
        else
          process_basic_item(item)
        end
      rescue ZDBA::InvalidQueryError => e
        ZDBA.logger.error do
          "worker[#{@name}]: failed to execute query `#{item[:name]}`: #{e.message} #{e.backtrace[0]}"
        end
      end

      send_liveness_check(1)
    rescue ZDBA::DatabaseConnectionError => e
      ZDBA.logger.error { "worker[#{@name}]: database is down" }
      send_liveness_check(0)
    rescue StandardError => e
      ZDBA.logger.error { [e.inspect, e.backtrace[0]] }
      send_liveness_check(0)
    end

    def send_liveness_check(value)
      throttle(name: 'alive', poll_interval: 10) do
        publish('alive', value)
      end
    end

    def process_basic_item(item)
      throttle(**item) do
        value = @connection.fetch_one(item[:query])&.dig(0)
        value = item[:default] if value.nil?

        publish(item[:name], value)
      end
    end

    def process_discovery_rule(item)
      throttle(**item) do
        key = format(DISCOVERY_RULE_KEY_FORMAT, item[:name]).upcase
        discovered = @connection.fetch_many(item[:query]).map do |(value)|
          { key => value }
        end

        publish(item[:name], { data: discovered })
      end
    end

    def process_discovery_item(item)
      throttle(**item) do
        @connection.fetch_many(item[:query]) do |(key, value)|
          key = format(DISCOVERY_ITEM_KEY_FORMAT, item[:name], key)

          publish(key, value)
        end
      end
    end

    def throttle(name:, poll_interval:, **)
      last_poll = @last_polls[name]

      return if last_poll && (poll_interval > ZDBA.current_time - last_poll)

      @last_polls[name] = ZDBA.current_time

      yield
    end

    def publish(key, value)
      value = JSON.dump(value) unless value.is_a?(String)

      @queue.push({ host: @name, key:, value:, clock: ZDBA.current_time })
    end
  end
end
