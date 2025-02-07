# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pause do
  describe 'adapter' do
    let(:configuration) { Pause::Configuration.new }

    before do
      described_class.adapter = nil
      allow(described_class).to receive(:config).and_return(configuration)
      configuration.configure { |c| c.sharded = sharded }
    end

    context 'pause is sharded' do
      let(:sharded) { true }

      it 'is a ShardedAdapter' do
        expect(described_class.adapter).to be_a(Pause::Redis::ShardedAdapter)
      end
    end

    context 'pause is not sharded' do
      let(:sharded) { false }

      it 'is an Adapter' do
        expect(described_class.adapter).to be_a(Pause::Redis::Adapter)
      end
    end
  end
end
