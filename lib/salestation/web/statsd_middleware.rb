# frozen_string_literal: true

module Salestation
  class Web < Module
    class StatsdMiddleware
      EXTRA_TAGS_ENV_KEY = 'salestation.statsd.tags'

      DURATION_MILLISECOND_PRECISION = 3

      def initialize(app, statsd, logger, metric:, tagged_params: {})
        @app = app
        @statsd = statsd
        @metric = metric
        @tagged_params = tagged_params
        @logger = logger
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

        params = env['rack.request.form_hash']

        if path != '/healthz'
          @logger.error("Metric body:")
          pp path
          pp params
        end

        param_tags = @tagged_params.map do |tag, allowed_values|
          val = if params.has_key?(tag)
            if allowed_values.include?(params[tag])
              params[tag]
            else
              'other'
            end
          else
            'N/A'
          end

          "#{tag}:#{val}"
        end

        @logger.error("tags: #{param_tags}")
        @logger.error("custom tags: #{env[EXTRA_TAGS_ENV_KEY]}")
        
        tags = [
          "path:#{path}",
          "method:#{method}",
          "status:#{status}",
          "status_class:#{status / 100}xx",
        ] + env.fetch(EXTRA_TAGS_ENV_KEY, []) + param_tags

        @statsd.distribution(@metric, duration_ms(from: start), tags: tags)

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
