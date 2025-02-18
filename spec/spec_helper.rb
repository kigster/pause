# frozen_string_literal: true

# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration

require 'fileutils'

require 'simplecov'
SimpleCov.start

require 'pause'

if ENV['PAUSE_REAL_REDIS']
  require 'pause/redis/adapter'
  puts
  puts "NOTE: Using real Redis-server at #{Pause::Redis::Adapter.redis.inspect}\n\n"
else
  require 'fakeredis/rspec'
end

RSpec.configure do |config|
  rspec_dir = './.spec'
  FileUtils.mkdir_p(rspec_dir)
  config.example_status_persistence_file_path = "#{rspec_dir}/results.txt"

  config.order = 'random'

  if ENV['PAUSE_REAL_REDIS']
    config.before do
      Pause::Redis::Adapter.redis.flushdb
    end
  end
end
