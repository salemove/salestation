# frozen_string_literal: true

require 'http/accept'

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
          return Success(nil) if @allowed_headers.empty?

          mime_types = HTTP::Accept::MediaTypes.parse(header_value.to_s).map(&:mime_type)

          if (@allowed_headers & mime_types).any?
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
