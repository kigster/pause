# frozen_string_literal: true

require 'spec_helper'
require 'date'
require 'timecop'

describe Pause::Redis::Adapter do
  let(:resolution) { 10 }
  let(:adapter) { described_class.new(Pause.config) }
  let(:redis_conn) { adapter.send(:redis) }
  let(:history) { 60 }
  let(:configuration) { Pause::Configuration.new }

  before do
    allow(Pause).to receive(:config).and_return(configuration)
    allow(Pause.config).to receive_messages(resolution: resolution, history: history)
    redis_conn.flushall
  end

  describe '#increment' do
    let(:scope) { 'blah' }
    let(:identifier) { '213213' }
    let(:tracked_key) { "i:#{scope}:|#{identifier}|" }
    let(:now) { Time.now.to_i }

    it 'adds key to a redis set' do
      adapter.increment(scope, identifier, Time.now.to_i)
      set = redis_conn.zrange(tracked_key, 0, -1, with_scores: true)
      expect(set).not_to be_empty
      expect(set.size).to be(1)
      expect(set[0].size).to be(2)
    end

    describe 'when increment is called' do
      let(:redis_conn_double) { instance_double(Redis) }

      before do
        allow(adapter).to receive(:with_multi).and_yield(redis_conn_double)
      end

      it 'calls zincrby on the redis connection' do
        allow(redis_conn_double).to receive(:expire)
        expect(redis_conn_double).to receive(:zincrby)

        adapter.increment(scope, identifier, Time.now.to_i)
      end

      it 'calls expire on the redis key' do
        expect(redis_conn_double).to receive(:expire).with(tracked_key, history)
        allow(redis_conn_double).to receive(:zincrby)

        adapter.increment(scope, identifier, Time.now.to_i)
      end
    end

    context 'removing two elements' do
      let(:to_delete) { 2 }
      let(:period_start) { adapter.period_marker(resolution, now) }
      let(:period_end) { adapter.period_marker(resolution, now + resolution) }

      around do |example|
        Timecop.freeze(now) { example.run }
      end

      before do
        redis_conn.flushall
        adapter.time_blocks_to_keep = 1
        allow(redis_conn).to receive(:zrem).with(tracked_key, [period_start])
        allow(redis_conn).to receive(:zrem).with(tracked_key, [period_start, period_end])
      end

      it 'removes old elements' do
        adapter.increment(scope, identifier, now.to_i)
        to_delete.times do |t|
          next_time = now + (adapter.resolution + t + 1)
          adapter.increment(scope, identifier, next_time.to_i)
        end
      end
    end
  end

  describe '#expire_block_list' do
    let(:scope) { 'a' }
    let(:expired_identifier) { '123' }
    let(:blocked_identifier) { '124' }

    it 'clears all entries with score older than now' do
      now = Time.now

      Timecop.freeze now - 10 do
        adapter.rate_limit!(scope, expired_identifier, 5)
      end

      Timecop.freeze now - 4 do
        adapter.rate_limit!(scope, blocked_identifier, 5)
      end

      adapter.expire_block_list(scope)

      expect(redis_conn.zscore('b:|a|', blocked_identifier)).not_to be_nil
      expect(redis_conn.zscore('b:|a|', expired_identifier)).to be_nil
    end
  end

  describe '#rate_limited?' do
    let(:scope) { 'ipn:follow' }
    let(:identifier) { '123461234' }
    let(:blocked_key) { "b:#{key}" }
    let(:ttl) { 110_000 }

    it 'returns true if blocked' do
      adapter.rate_limit!(scope, identifier, ttl)
      expect(adapter.rate_limited?(scope, identifier)).to be true
    end
  end

  describe '#tracked_key' do
    it 'prefixes key' do
      expect(adapter.send(:tracked_key, 'abc', '12345')).to eq('i:abc:|12345|')
    end
  end

  describe '#enable' do
    it 'deletes the disabled flag in redis' do
      adapter.disable('boom')
      expect(adapter.disabled?('boom')).to be true
      adapter.enable('boom')
      expect(adapter.disabled?('boom')).to be false
    end
  end

  describe '#disable' do
    it 'sets the disabled flag in redis' do
      expect(adapter.enabled?('boom')).to be true
      adapter.disable('boom')
      expect(adapter.enabled?('boom')).to be false
    end
  end

  describe '#rate_limit!' do
    it 'rate limits a key for a specific ttl' do
      expect(adapter.rate_limited?('blah', '1')).to be false
      adapter.rate_limit!('blah', '1', 10)
      expect(adapter.rate_limited?('blah', '1')).to be true
    end

    describe 'redis internals' do
      let(:scope) { 'ipn:follow' }
      let(:identifier) { '1234' }
      let(:blocked_key) { "b:|#{scope}|" }
      let(:ttl) { 110_000 }

      it 'saves ip to redis with expiration' do
        time = Time.now
        Timecop.freeze time do
          adapter.rate_limit!(scope, identifier, ttl)
        end
        expect(redis_conn.zscore(blocked_key, identifier)).not_to be_nil
        expect(redis_conn.zscore(blocked_key, identifier)).to eq(time.to_i + ttl)
      end
    end
  end

  describe '#delete_rate_limited_keys' do
    context 'with blocked items' do
      before do
        adapter.rate_limit!('boom', '1', 10)
        adapter.rate_limit!('boom', '2', 10)

        expect(adapter.rate_limited?('boom', '1')).to be true
        expect(adapter.rate_limited?('boom', '2')).to be true
      end

      it 'calls redis del with all keys' do
        adapter.delete_rate_limited_keys('boom')

        expect(adapter.rate_limited?('boom', '1')).to be false
        expect(adapter.rate_limited?('boom', '2')).to be false
      end

      it 'returns the number of unblocked items' do
        expect(adapter.delete_rate_limited_keys('boom')).to eq(2)
      end
    end

    context 'with no blocked items' do
      it 'returns 0' do
        expect(adapter.delete_rate_limited_keys('boom')).to eq(0)
      end
    end
  end

  describe '#delete_rate_limit_key' do
    it 'calls redis del with all keys' do
      adapter.rate_limit!('boom', '1', 10)
      adapter.rate_limit!('boom', '2', 10)

      expect(adapter.rate_limited?('boom', '1')).to be true
      expect(adapter.rate_limited?('boom', '2')).to be true

      adapter.delete_rate_limited_key('boom', '1')

      expect(adapter.rate_limited?('boom', '1')).to be false
      expect(adapter.rate_limited?('boom', '2')).to be true
    end
  end
end
