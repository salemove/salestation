# frozen_string_literal: true

module Salestation
  class Web < Module
    class RequestLogger
      EXTRA_FIELDS_ENV_KEY = 'salestation.request_logger.fields'

      DURATION_PRECISION = 6
      REMOTE_ADDR = 'REMOTE_ADDR'
      REQUEST_URI = 'REQUEST_URI'
      REQUEST_METHOD = 'REQUEST_METHOD'
      QUERY_STRING = 'QUERY_STRING'
      CONTENT_TYPE = 'CONTENT_TYPE'
      HTTP_USER_AGENT = 'HTTP_USER_AGENT'
      HTTP_ACCEPT = 'HTTP_ACCEPT'
      HTTP_ORIGIN = 'HTTP_ORIGIN'
      SERVER_NAME = 'SERVER_NAME'
      GLIA_ACCOUNT_ID = 'HTTP_GLIA_ACCOUNT_ID'
      GLIA_USER_ID = 'HTTP_GLIA_USER_ID'

      def initialize(app, logger, log_response_body: false, level: :info)
        @app = app
        @logger = logger
        @log_response_body = log_response_body
        @level = level
      end

      def call(env)
        began_at = system_monotonic_time

        @app.call(env).tap do |status, headers, body|
          @logger.public_send(
            determine_log_level(status),
            'Processed request',
            response_log(env, status, headers, body, began_at)
          )
        end
      end

      private

      def determine_log_level(status)
        if status >= 500
          :error
        elsif status >= 400
          :info
        else
          @level
        end
      end

      def response_log(env, status, headers, body, began_at)
        log = {
          remote_addr:     env[REMOTE_ADDR],
          method:          env[REQUEST_METHOD],
          path:            env[REQUEST_URI],
          query:           env[QUERY_STRING],
          content_type:    env[CONTENT_TYPE],
          http_agent:      env[HTTP_USER_AGENT],
          http_accept:     env[HTTP_ACCEPT],
          http_origin:     env[HTTP_ORIGIN],
          server_name:     env[SERVER_NAME],
          status:          status,
          duration:        duration(from: began_at),
          glia_account_id: env[GLIA_ACCOUNT_ID],
          glia_user_id:    env[GLIA_USER_ID],
          headers:         headers
        }

        if status >= 400
          log[:error] = body.join
        elsif @log_response_body
          log[:body] = body.join
        end

        extra_fields = env.fetch(EXTRA_FIELDS_ENV_KEY, {})
        log.merge!(extra_fields)
      end

      def duration(from:)
        (system_monotonic_time - from).round(DURATION_PRECISION)
      end

      def system_monotonic_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
