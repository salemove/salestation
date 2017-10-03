require 'securerandom'
require 'json'

module Salestation
  class Web < Module
    class RequestLogger

      REMOTE_ADDR = 'REMOTE_ADDR'.freeze
      REQUEST_URI = 'REQUEST_URI'.freeze
      REQUEST_METHOD = 'REQUEST_METHOD'.freeze
      QUERY_STRING   = 'QUERY_STRING'.freeze
      CONTENT_TYPE = 'CONTENT_TYPE'.freeze
      HTTP_USER_AGENT = 'HTTP_USER_AGENT'.freeze
      HTTP_ACCEPT = 'HTTP_ACCEPT'.freeze
      SERVER_NAME = 'SERVER_NAME'.freeze
      JSON_CONTENT_TYPE = 'application/json'.freeze

      def initialize(app, logger, log_response_body: true)
        @app = app
        @logger = logger
        @log_response_body = log_response_body
      end

      def call(env)
        request_id = SecureRandom.hex(4)
        request_logger = Logger.new(@logger, request_id)

        env['request_logger'] = request_logger
        began_at = Time.now

        request_logger.info('Received request', request_log(env))
        @app.call(env).tap do |status, headers, body|
          type = status >= 500 ? :error : :info
          request_logger.public_send(type, 'Processed request', response_log(env, status, headers, body, began_at))
        end
      end

      private

      def request_log(env)
        {
          remote_addr:  env[REMOTE_ADDR],
          method:       env[REQUEST_METHOD],
          path:         env[REQUEST_URI],
          query:        env[QUERY_STRING],
          content_type: env[CONTENT_TYPE],
          http_agent:   env[HTTP_USER_AGENT],
          http_accept:  env[HTTP_ACCEPT],
          server_name:  env[SERVER_NAME]
        }
      end

      def response_log(env, status, headers, body, began_at)
        response_payload =
          if status >= 400
            { error: parse_body(body, env) }
          elsif @log_response_body
            { body: parse_body(body, env) }
          else
            {}
          end

        {
          path: env[REQUEST_URI],
          method: env[REQUEST_METHOD],
          status: status,
          duration: Time.now - began_at,
          headers: headers
        }.merge(response_payload)
      end

      def parse_body(body, env)
        begin
          # Rack body is an array
          return {} if body.empty?
          JSON.parse(body.join)
        rescue Exception
          {error: 'Failed to parse response body'}
        end
      end

      class Logger
        def initialize(logger, request_id)
          @logger = logger
          @request_id = request_id
        end

        [:debug, :info, :warn, :error].each do |name|
          define_method(name) do |msg, metadata = {}|
            @logger.public_send(name, msg, metadata.merge(request_id: @request_id))
          end
        end
      end
    end
  end
end
