Pause
======

[![Build status](https://secure.travis-ci.org/wanelo/pause.png)](http://travis-ci.org/wanelo/pause)

Pause is a Redis-backed rate-limiting client. Use it to track events, with
rules around how often they are allowed to occur within configured time checks.

## Installation

Add this line to your application's Gemfile:

    gem 'pause'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pause

## Usage

### Configuration

Configure Pause. This could be in a Rails initializer.

  * resolution - The time resolution (in seconds) defining the minimum period into which action counts are
                 aggregated. This defines the size of the persistent store. The higher the number, the less data needs
                 to be persisted in Redis.
  * history - The maximum amount of time (in seconds) that data is persisted

```ruby
Pause.configure do |config|
  config.redis_host = "127.0.0.1"
  config.redis_port = 6379
  config.redis_db   = 1

  config.resolution = 600
  config.history    = 86400
end
```

### Actions

Define local actions for your application. Actions define a scope by
which they are identified in the persistent store, and a set of checks.  Checks define various
thresholds (`max_allowed`) against periods of time (`period_seconds`). When a threshold it triggered,
the action is rate limited, and stays rate limited for the duration of `block_ttl` seconds.

#### Checks

Checks are configured with the following arguments (which can be passed as an array, or a symbol hash):

  * `period_seconds` - time window this is a time period against which an action is tested
  * `max_allowed` - the maximum number of times an action can be incremented during this particular time period before rate limiting is triggered.
  * `block_ttl` - amount time (seconds) an action stays rate limited after threshold is reached.

#### Scope

Scope is simple string used to identify this action in the Redis store, and is appended to all keys.
Therefore it is advised to keep scope as short as possible to reduce memory requirements of the store.

#### Resolution

Note that your resolution must be less than or equal to the smallest `period_seconds` value in your checks.
In other words, if your shortest check is 1 minute, you could set resolution to 1 minute or smaller.

#### Example

```ruby
require 'pause'

class FollowAction < Pause::Action
  scope "f"
  check period_seconds:   60, max_allowed:  100, block_ttl: 3600
  check period_seconds: 1800, max_allowed: 2000, block_ttl: 3600
end
```

When an event occurs, you increment an instance of your action, optionally with a timestamp and count. This saves
data into a redis store, so it can be checked later by other processes. Timestamps should be in unix epoch format.

```ruby
class FollowsController < ApplicationController
  def create
    action = FollowAction.new(user.id)
    if action.ok?
      # do stuff!
      action.increment!
    else
      # action is rate limited, either skip
      # or show error, depending on the context.
    end
  end
end

class OtherController < ApplicationController
  def index
    action = OtherAction.new(params[:thing])
    if action.ok?
      action.increment!(params[:count].to_i, Time.now.to_i)
    end
  end
end
```

If more data is needed about why the action is blocked, the `analyze` can be called

```ruby
action = MyAction.new("thing")

while true
  action.increment!

  blocked_action = action.analyze

  if blocked_action
    puts blocked_action.identifier
    puts blocked_action.sum
    puts blocked_action.timestamp

    puts blocked_aciton.period_check.inspect
  end

  sleep 1
end
```

## Contributing

Want to make it better? Cool. Here's how:

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new pull request
