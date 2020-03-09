# frozen_string_literal: true

module Salestation
  class Web < Module
    class StatsdMiddleware
      EXTRA_TAGS_ENV_KEY = 'salestation.statsd.tags'

      def initialize(app, statsd, metric:)
        @app = app
        @statsd = statsd
        @metric = metric
      end

      def call(env)
        start = Time.now

        status, header, body = @app.call env

        method = env['REQUEST_METHOD']
        path =
          if route = env['sinatra.route']
            route.split(' ').last
          else
            'unknown-route'
          end

        tags = [
          "path:#{ path }",
          "method:#{ method }",
          "status:#{ status }"
        ] + env.fetch(EXTRA_TAGS_ENV_KEY, [])

        @statsd.timing(@metric, (Time.now - start) * 1000, tags: tags)

        [status, header, body]
      end
    end
  end
end
