# typed: true
# frozen_string_literal: true

require "thor"
require "tapioca/helpers/cli_helper"

module Tapioca
  module Logging
    def logger
      @logger ||= if ENV["TAPIOCA_DEVELOPMENT"]
        logger = Logger.new("tapioca.log")
        Tapioca::LoggerAdapter.new(logger)
      else
        Tapioca::ThorLogger.new
      end
    end
  end
end

module Tapioca
  class LoggerAdapter
    def initialize(logger)
      @logger = logger
    end

    def info(message = "", *_color)
      @logger.info(message)
    end

    def error(message = "", *_color)
      @logger.error(message)
    end
  end

  class ThorLogger < Logger
    include Thor::Base
    include CliHelper

    def info(...)
      say(...)
    end

    def error(...)
      # This is Tapioca's `say_error`, not Thor's `say_error`
      say_error(...)
    end
  end
end
