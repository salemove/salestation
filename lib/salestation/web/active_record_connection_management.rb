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
          clear_connections unless testing
        end
        [status, headers, proxy]
      rescue Exception
        clear_connections unless testing
        raise
      end

      def clear_connections
        if ActiveRecord.version >= Gem::Version.new('7.1')
          # For ActiveRecord 7.1 and newer
          ActiveRecord::Base.connection_handler.clear_active_connections!
        else
          # For ActiveRecord 6.1 to 7.0
          ActiveRecord::Base.clear_active_connections!
        end
      end
    end
  end
end
