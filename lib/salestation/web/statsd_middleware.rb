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

        method, path = env['sinatra.route'].split

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
