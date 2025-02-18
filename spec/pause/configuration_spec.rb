# frozen_string_literal: true

require 'spec_helper'

describe Pause::Configuration, '#configure' do
  subject { described_class.new }

  it 'allows configuration via block' do
    subject.configure do |c|
      c.redis_host = '128.23.12.8'
      c.redis_port = '2134'
      c.redis_db = '13'

      c.resolution = 5000
      c.history = 6000
      c.sharded = true
    end

    expect(subject.redis_host).to eq('128.23.12.8')
    expect(subject.redis_port).to eq(2134)
    expect(subject.redis_db).to eq('13')

    expect(subject.resolution).to eq(5000)
    expect(subject.history).to eq(6000)
    expect(subject.sharded).to be true
  end

  it 'provides redis defaults' do
    subject.configure do |config|
      # do nothing
    end

    expect(subject.redis_host).to eq('127.0.0.1')
    expect(subject.redis_port).to eq(6379)
    expect(subject.redis_db).to eq('1')
    expect(subject.resolution).to eq(600) # 10 minutes
    expect(subject.history).to eq(86_400) # one day
    expect(subject.sharded).to be false
  end
end
