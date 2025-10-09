# frozen_string_literal: true

module ZDBA
  class Config
    extend(::Forwardable)

    def_delegators :@store, :[], :[]=, :fetch, :key?, :dig

    def initialize(config_path)
      @config_file = ::Pathname.new(config_path).realpath
      @schema = ::JSON.parse(::ZDBA.root.join('schemas/config.json').read)
      @store = {
        logger: {
          level: 'info'
        },
        sender: {
          connect_timeout: 10,
          batch_size: 100,
          threads: 1
        },
        global: {
          poll_interval: 30
        }
      }

      prepare_config
    end

    private

    def prepare_config
      config = load_config_file(@config_file)
      apply_defaults(config)
      deep_merge!(@store, config)
    end

    def load_config_file(config_file)
      config = load_yaml_file(config_file)
      validate_schema!(@schema, config)

      config[:databases].each do |db|
        next unless db[:items] || db[:include]

        db[:items] ||= []

        db[:include]&.each do |path|
          path = ::Pathname.new(path)
          path = config_file.dirname.join(path) unless path.absolute?
          items = load_yaml_file(path)

          validate_schema!(@schema, items, fragment: '#/$defs/items')

          db[:items].concat(items)
        end
      end

      config
    end

    def apply_defaults(config)
      config[:databases].each do |db|
        db[:poll_interval] ||= config[:global][:poll_interval]

        db[:items]&.each do |item|
          item[:poll_interval] ||= db[:poll_interval]
        end
      end
    end

    def validate_schema!(schema, data, **)
      ::JSON::Validator.validate!(schema, data, **)
    end

    def load_yaml_file(file)
      ::YAML.safe_load_file(file, symbolize_names: true, aliases: true)
    end

    def deep_merge!(left, right)
      left.merge!(right) do |_key, old_value, new_value|
        case old_value
        when ::Hash
          deep_merge!(old_value, new_value)
        when ::Array
          old_value + new_value
        else
          new_value
        end
      end
    end
  end
end
