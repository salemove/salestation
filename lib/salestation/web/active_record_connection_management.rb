# frozen_string_literal: true

module Salestation
  class Web < Module
    class ActiveRecordConnectionManagement
      def initialize(app)
        @app = app
      end

      def call(env)
        testing = env['rack.test']

        status, headers, body = @app.call(env)
        proxy = ::Rack::BodyProxy.new(body) do
          ActiveRecord::Base.clear_active_connections! unless testing
        end
        [status, headers, proxy]
      rescue Exception
        ActiveRecord::Base.clear_active_connections! unless testing
        raise
      end
    end
  end
end
