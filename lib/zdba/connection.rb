# frozen_string_literal: true

module ZDBA
  class Connection
    def initialize(config)
      @config = config
    end

    def connection
      @connection ||= Sequel.jdbc(@config)
    end

    def disconnect
      @connection&.disconnect
      @connection = nil
    end

    def fetch_one(query)
      execute(query, fetch_size: 1) { |row| return row }
    end

    def fetch_many(query, fetch_size: 100, &block)
      if block
        execute(query, fetch_size:, &block)
      else
        rows = []
        execute(query, fetch_size:) { |row| rows << row }
        rows
      end
    end

    private

    def execute(query, fetch_size:)
      connection.execute(query) do |rs|
        rs.fetch_size = fetch_size
        meta = rs.meta_data

        while rs.next
          row = Array.new(meta.column_count) do |i|
            # { name: meta.get_column_label(i + 1), value: rs.get_object(i + 1) }
            rs.get_object(i + 1)
          end

          yield(row)
        end
      ensure
        rs.close
      end
    rescue Sequel::DatabaseConnectionError => e
      raise ZDBA::DatabaseConnectionError, e.message
    rescue Sequel::DatabaseError => e
      raise ZDBA::InvalidQueryError, e.message
    end
  end
end
