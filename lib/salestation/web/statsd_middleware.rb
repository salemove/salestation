# frozen_string_literal: true

module Salestation
  class Web < Module
    class StatsdMiddleware
      EXTRA_TAGS_ENV_KEY = 'salestation.statsd.tags'

      DURATION_MILLISECOND_PRECISION = 3

      def initialize(app, statsd, metric:)
        @app = app
        @statsd = statsd
        @metric = metric
      end

      def call(env)
        start = system_monotonic_time

        status, header, body = @app.call env

        method = env['REQUEST_METHOD']
        path =
          if route = env['sinatra.route']
            route.split(' ').last
          else
            'unknown-route'
          end

        tags = [
          "path:#{path}",
          "method:#{method}",
          "status:#{status}",
          "status_class:#{status / 100}xx"
        ] + env.fetch(EXTRA_TAGS_ENV_KEY, [])

        @statsd.timing(@metric, duration_ms(from: start), tags: tags)

        [status, header, body]
      end

      private

      def duration_ms(from:)
        ((system_monotonic_time - from) * 1000).round(DURATION_MILLISECOND_PRECISION)
      end

      def system_monotonic_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
