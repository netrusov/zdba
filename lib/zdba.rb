# frozen_string_literal: true

require 'forwardable'
require 'json'
require 'logger'
require 'pathname'
require 'yaml'

require 'json-schema'
require 'sequel'

require_relative 'zdba/config'
require_relative 'zdba/connection'
require_relative 'zdba/log_formatters/base'
require_relative 'zdba/log_formatters/json'
require_relative 'zdba/log_formatters/plain'
require_relative 'zdba/logger'
require_relative 'zdba/manager'
require_relative 'zdba/sender'
require_relative 'zdba/version'
require_relative 'zdba/worker'

module ZDBA
  module_function

  DatabaseConnectionError = ::Class.new(::StandardError)
  InvalidQueryError = ::Class.new(::StandardError)

  def root
    @root ||= ::Pathname.new(__dir__).join('..')
  end

  def logger
    @logger ||= ::ZDBA::Logger.new($stdout).tap do |l|
      l.formatter = ::ZDBA::LogFormatters::Plain.new
    end
  end

  def current_time
    ::Process.clock_gettime(::Process::CLOCK_REALTIME)
  end
end
