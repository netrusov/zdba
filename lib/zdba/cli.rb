# frozen_string_literal: true

require 'thor'

module ZDBA
  class CLI < ::Thor
    desc 'start', 'Start the service'
    option :config, aliases: %w[-c], type: :string, required: true, desc: 'Config file path'
    def start(...)
      config = ::ZDBA::Config.new(options[:config])

      ::ZDBA.logger.level = config[:logger][:level]
      ::ZDBA.logger.formatter = ::ZDBA::LogFormatters::JSON.new if config[:logger][:json]

      config[:require]&.each do |path|
        require(path)
      end

      ::ZDBA::Manager.new(config).run
    end

    desc 'init OUTPUT_DIR', 'Initialize the project'
    option :adapters, aliases: %w[-a], type: :array, default: [], desc: 'Adapter name(s) to copy item templates for'
    def init(out, ...)
      require('fileutils')

      src = ::ZDBA.root.join('templates')
      out = ::Pathname.new(out).expand_path.tap(&:mkpath)

      config_out = out.join('config.yml')
      ::FileUtils.cp(src.join('config.yml'), config_out) unless config_out.exist?

      return if (adapters = options[:adapters]).empty?

      adapters.each do |adapter|
        items_src = src.join('items', adapter)

        unless items_src.exist?
          say("no item templates found for '#{adapter}' adapter")
          next
        end

        items_out = out.join('items', adapter).tap(&:mkpath)

        items_src.each_child do |child|
          next if items_out.join(child.basename).exist?

          ::FileUtils.cp(child, items_out)
        end
      end
    end
  end
end
