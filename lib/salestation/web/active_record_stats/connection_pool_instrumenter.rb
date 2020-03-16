# frozen_string_literal: true

module Salestation
  module ActiveRecordStats
    class ConnectionPoolInstrumenter
      DEFAULT_PREFIX = 'db.connection_pool'
      EXECUTION_INTERVAL_SECONDS = 1
      EXECUTION_TIMEOUT_SECONDS = 1

      def initialize(connection_pool:, statsd:, prefix: DEFAULT_PREFIX)
        @connection_pool = connection_pool
        @statsd = statsd
        @prefix = prefix
      end

      def start(execution_interval: EXECUTION_INTERVAL_SECONDS)
        Concurrent::TimerTask.execute(
          execution_interval: execution_interval,
          timeout_interval: EXECUTION_TIMEOUT_SECONDS
        ) { instrument! }
      end

      def instrument!
        # ActiveRecord::Base.connection_pool.stat returns
        # { size: 15, connections: 1, busy: 1, dead: 0, idle: 0, waiting: 0, checkout_timeout: 5 }
        @connection_pool.stat.each_pair do |metric, value|
          send_gauge(metric, value)
        end
      end

      private

      def send_gauge(metric, value)
        @statsd.gauge([@prefix, metric].join('.'), value)
      end
    end
  end
end
