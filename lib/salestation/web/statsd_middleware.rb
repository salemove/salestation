module Salestation
  class Web < Module
    class StatsdMiddleware

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

        @statsd.timing(@metric, (Time.now - start) * 1000, tags: [
          "path:#{ path }",
          "method:#{ method }",
          "status:#{ status }"
        ])

        [status, header, body]
      end
    end
  end
end
