# frozen_string_literal: true

require 'redis'
require 'colored2'
require 'pause/version'
require 'pause/configuration'
require 'pause/action'
require 'pause/analyzer'
require 'pause/logger'
require 'pause/redis/adapter'
require 'pause/redis/sharded_adapter'
require 'pause/rate_limited_event'

module Pause
  PeriodCheck = Struct.new(:period_seconds, :max_allowed, :block_ttl) do
    def initialize(*args, period_seconds: nil, max_allowed: nil, block_ttl: nil)
      if args.any?
        super(*args)
      else
        super(period_seconds, max_allowed, block_ttl)
      end
    end

    def <=>(other)
      period_seconds <=> other.period_seconds
    end
  end

  SetElement = Struct.new(:ts, :count) do
    def <=>(other)
      ts <=> other.ts
    end
  end

  class << self
    def analyzer
      @analyzer ||= Pause::Analyzer.new
    end

    def adapter
      @adapter ||= if config.sharded
                     Pause::Redis::ShardedAdapter.new(config)
                   else
                     Pause::Redis::Adapter.new(config)
                   end
    end

    attr_writer :adapter

    def configure(&)
      @configure ||= Pause::Configuration.new.configure(&)
    end

    def config(&)
      configure(&)
    end
  end
end
