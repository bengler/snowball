require "bundler"
Bundler.require

require "snowball/version"
require "snowball/environment"
require "snowball/config"
require "snowball/file_resolver"
require "snowball/rack"
require "snowball/cache"
require "snowball/roller"
require "logger"

module Snowball
  class InvalidOptionError < StandardError; end
  class ConfigurationError < StandardError; end

  class << self
    attr_accessor :logger
  end
  self.logger = ::Logger.new($stderr)
  self.logger.level = ::Logger::FATAL
end
