# frozen_string_literal: true

::Warbler::Config.new do |config|
  config.features = %w[compiled]
  config.bundler = false
end
