# frozen_string_literal: true

require 'spec_helper'

module Pause
  RSpec.describe PeriodCheck do
    let(:period_seconds) { 10 }
    let(:max_allowed) { 2 }
    let(:block_ttl) { 10 }

    let(:period_check_1) do
      described_class.new(
        period_seconds: period_seconds,
        max_allowed: max_allowed,
        block_ttl: block_ttl
      )
    end

    let(:period_check_2) do
      described_class.new(
        period_seconds: 2 * period_seconds,
        max_allowed: 1.5 * max_allowed,
        block_ttl:
      )
    end

    describe '#==' do
      let(:period_check_3) do
        described_class.new(
          period_seconds: 2 * period_seconds,
          max_allowed: 1.5 * max_allowed,
          block_ttl:
        )
      end

      it 'is equal' do
        expect(period_check_3).to eq(period_check_2)
      end

      it 'is not equal' do
        expect(period_check_3).not_to eq(period_check_1)
      end

      describe '#sort' do
        let(:list) { [period_check_2, period_check_1] }

        it 'sorts' do
          expect(list.sort).to eq([period_check_1, period_check_2])
        end
      end
    end
  end
end
