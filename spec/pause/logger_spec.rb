# frozen_string_literal: true

require 'spec_helper'

describe Pause::Logger do
  describe 'when accessed #puts' do
    before do
      expect($stdout).to receive(:puts).with('hello')
    end

    it 'calls through to puts without color' do
      described_class.puts('hello')
    end
  end

  describe 'when accessed via #fatal' do
    before do
      expect($stderr).to receive(:puts).with("\e[31mwhoops\e[0m")
    end

    it 'calls through to puts with color' do
      described_class.fatal('whoops')
    end
  end
end
