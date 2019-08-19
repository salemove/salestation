# frozen_string_literal: true

module Salestation
  class Web < Module
    module InputValidators
      class ContentTypeHeader
        include Deterministic::Prelude

        def self.[](*allowed_headers)
          new(allowed_headers)
        end

        def initialize(allowed_headers)
          @allowed_headers = allowed_headers
        end

        def call(header_value)
          # Some headers can have additional information such as `multipart/form-data`
          parsed_header_value = header_value ? header_value.split(';').first : nil

          header_valid = @allowed_headers.empty? || @allowed_headers.include?(parsed_header_value)

          if header_valid
            Success(nil)
          else
            Failure(App::Errors::UnsupportedMediaType.new(
              message: "Unsupported Content-Type Header '#{header_value}'",
              debug_message: "Available Content-Type Headers are #{@allowed_headers.join(', ')}"
            ))
          end
        end
      end
    end
  end
end
