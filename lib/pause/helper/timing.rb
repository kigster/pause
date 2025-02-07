# frozen_string_literal: true

module Pause
  module Helper
    module Timing
      def period_marker(resolution, timestamp = Time.now)
        timestamp.to_i / resolution * resolution
      end
    end
  end
end
