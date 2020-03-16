# frozen_string_literal: true

require_relative '../thread_accessors.rb'
require_relative './collector'

module Salestation
  class Web < Module
    class ActiveRecordStatsMiddleware
      extend ThreadAccessors

      thread_mattr_accessor :db_runtime, :db_queries

      DEFAULT_PREFIX = 'web.request.db'

      def initialize(app, statsd, metric_prefix: DEFAULT_PREFIX)
        @app = app
        @collector = Collector.new(statsd, prefix: metric_prefix)
        @collector.subscribe
      end

      def call(env)
        @collector.reset

        @app.call(env)
      ensure
        @collector.emit(tags: tags(env))
      end

      private

      def tags(env)
        method = env['REQUEST_METHOD']

        path =
          if (route = env['sinatra.route'])
            route.split(' ').last
          else
            'unknown-route'
          end

        %W[method:#{method} path:#{path}]
      end
    end
  end
end
