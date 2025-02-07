# frozen_string_literal: true

module Pause
  # @description Logger class for Pause
  class Logger
    class << self
      def puts(message)
        $stdout.puts message
      end

      def fatal(message)
        # rubocop: disable Style/StderrPuts
        $stderr.puts message.red
        # rubocop: enable Style/StderrPuts
      end
    end
  end
end
