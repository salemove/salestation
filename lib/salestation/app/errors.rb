# frozen_string_literal: true

module Salestation
  class App
    module Errors
      class Error < Dry::Struct
        attribute? :base_error, Types::Coercible::Hash

        def self.from(base_error, overrides = {})
          new(**overrides, base_error: base_error.to_h)
        end
      end

      class InvalidInput < Error
        attribute? :errors, Types::Strict::Hash
        attribute? :hints, Types::Coercible::Hash.default({}.freeze)
        attribute? :debug_message, Types::Strict::String
        attribute? :form_errors, Types::Strict::Bool.default(false)
      end

      class DependencyCurrentlyUnavailable < Error
        attribute? :message, Types::Strict::String
        attribute? :debug_message, Types::Strict::String
      end

      class RequestedResourceNotFound < Error
        attribute? :message, Types::Strict::String
        attribute? :debug_message, Types::Strict::String
      end

      class Forbidden < Error
        attribute? :message, Types::Strict::String
        attribute? :debug_message, Types::Strict::String
      end

      class Conflict < Error
        attribute? :message, Types::Strict::String
        attribute? :debug_message, Types::Strict::String
      end

      class NotAcceptable < Error
        attribute? :message, Types::Strict::String
        attribute? :debug_message, Types::Strict::String
      end

      class UnsupportedMediaType < Error
        attribute? :message, Types::Strict::String
        attribute? :debug_message, Types::Strict::String
      end

      class RequestEntityTooLarge < Error
        attribute? :message, Types::Strict::String
        attribute? :debug_message, Types::Strict::String
      end

      class BadRequest < Error
        attribute? :message, Types::Strict::String
        attribute? :debug_message, Types::Strict::String
      end
    end
  end
end
