# frozen_string_literal: true

module Salestation
  class Web < Module
    class RequestLogger

      REMOTE_ADDR = 'REMOTE_ADDR'
      REQUEST_URI = 'REQUEST_URI'
      REQUEST_METHOD = 'REQUEST_METHOD'
      QUERY_STRING = 'QUERY_STRING'
      CONTENT_TYPE = 'CONTENT_TYPE'
      HTTP_USER_AGENT = 'HTTP_USER_AGENT'
      HTTP_ACCEPT = 'HTTP_ACCEPT'
      SERVER_NAME = 'SERVER_NAME'

      def initialize(app, logger, log_response_body: false)
        @app = app
        @logger = logger
        @log_response_body = log_response_body
      end

      def call(env)
        began_at = Time.now

        @app.call(env).tap do |status, headers, body|
          type = status >= 500 ? :error : :info
          @logger.public_send(type, 'Processed request', response_log(env, status, headers, body, began_at))
        end
      end

      private

      def response_log(env, status, headers, body, began_at)
        log = {
          remote_addr:  env[REMOTE_ADDR],
          method:       env[REQUEST_METHOD],
          path:         env[REQUEST_URI],
          query:        env[QUERY_STRING],
          content_type: env[CONTENT_TYPE],
          http_agent:   env[HTTP_USER_AGENT],
          http_accept:  env[HTTP_ACCEPT],
          server_name:  env[SERVER_NAME],
          status:       status,
          duration:     Time.now - began_at,
          headers:      headers
        }

        if status >= 400
          log[:error] = body.join
        elsif @log_response_body
          log[:body] = body.join
        end

        log
      end
    end
  end
end
