# frozen_string_literal: true

require 'spec_helper'
require 'date'
require 'timecop'

describe Pause::Redis::ShardedAdapter do
  let(:resolution) { 10 }
  let(:adapter) { described_class.new(Pause.config) }
  let(:history) { 60 }
  let(:configuration) { Pause::Configuration.new }

  before do
    allow(Pause).to receive(:config).and_return(configuration)
    allow(Pause.config).to receive_messages(resolution: resolution, history: history)
  end

  describe '#all_keys' do
    it 'is not supported' do
      expect { adapter.all_keys('cake') }.to raise_error(Pause::Redis::OperationNotSupported)
    end
  end

  describe '#with_multi' do
    let(:redis) { adapter.send(:redis) }

    it 'does not call redis.multi' do
      expect(redis).not_to receive(:multi)
      expect { adapter.increment(:scope, 123, Time.now) }.not_to raise_error
    end
  end

  describe '#redis' do
    it 'does not use redis db when connecting' do
      expect(adapter.send(:redis_connection_opts)).not_to include(:db)
    end
  end
end
