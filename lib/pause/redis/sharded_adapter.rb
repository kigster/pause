module Pause
  module Redis
    class OperationNotSupported < StandardError
    end

    # This class encapsulates Redis operations used by Pause.
    # Operations that are not possible when data is sharded
    # raise an error.
    class ShardedAdapter < Adapter
      private

      def redis
        @redis_conn ||= ::Redis.new(host: Pause.config.redis_host,
          port: Pause.config.redis_port)
      end

      def keys(_key_scope)
        raise OperationNotSupported.new("Can not be executed when Pause is configured in sharded mode")
      end
    end
  end
end
