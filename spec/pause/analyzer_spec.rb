# frozen_string_literal: true

require 'spec_helper'
require 'timecop'

describe Pause::Analyzer do
  include Pause::Helper::Timing

  class FollowPushNotification < Pause::Action
    scope 'ipn:follow'
    check 20, 5, 12
    check 40, 7, 12
  end

  let(:resolution) { 10 }
  let(:analyzer) { Pause.analyzer }
  let(:action) { FollowPushNotification.new('1243123') }
  let(:history) { 60 }
  let(:configuration) { Pause::Configuration.new }
  let(:adapter) { Pause::Redis::Adapter.new(configuration) }

  before do
    allow(Pause.config).to receive_messages(resolution: resolution, history: history)
    allow(Pause).to receive_messages(config: configuration, adapter: adapter)
  end

  describe '#analyze' do
    it 'checks and blocks if max_allowed is reached' do
      time = Time.now
      expect(adapter).to receive(:rate_limit!).once.with(action.scope, '1243123', 12)
      Timecop.freeze time do
        5.times do
          action.increment!
          analyzer.check(action)
        end
      end
    end
  end

  describe '#check' do
    it 'returns nil if action is NOT blocked' do
      expect(analyzer.check(action)).to be_nil
    end

    it 'returns nil if action is NOT rate limited' do
      expect(action).not_to be_rate_limited
    end

    it 'returns blocked action if action is blocked' do
      Timecop.freeze Time.now do
        5.times do
          action.increment!
        end
        expect(analyzer.check(action)).to be_a(Pause::RateLimitedEvent)
      end
    end
  end
end
