# frozen_string_literal: true

module Salestation
  class Web < Module
    module InputValidators
      class AcceptHeader
        include Deterministic::Prelude

        def self.[](*allowed_headers)
          new(allowed_headers)
        end

        def initialize(allowed_headers)
          @allowed_headers = allowed_headers
        end

        def call(header_value)
          header_valid = @allowed_headers.empty? || @allowed_headers.include?(header_value)

          if header_valid
            Success(nil)
          else
            Failure(App::Errors::NotAcceptable.new(
              message: "Unsupported Accept Header '#{header_value}'",
              debug_message: "Available Accept Headers are #{@allowed_headers.join(', ')}"
            ))
          end
        end
      end
    end
  end
end
