require 'faraday'
require 'faraday_middleware'
require 'typhoeus'

module Chow
  module Call
    autoload :Connection,    "chow/call/connection"
    autoload :Configuration, "chow/call/configuration"
    autoload :Middleware,    "chow/call/middleware"
    autoload :VERSION,       "chow/call/version"

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.configure
      yield(configuration)
    end
  end
end
