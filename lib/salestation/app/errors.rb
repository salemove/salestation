# frozen_string_literal: true

module Salestation
  class App
    module Errors
      class InvalidInput < Dry::Struct
        attribute :errors, Types::Strict::Hash
        attribute :hints, Types::Coercible::Hash.default({})
      end

      class DependencyCurrentlyUnavailable < Dry::Struct
        attribute :message, Types::Strict::String
      end

      class RequestedResourceNotFound < Dry::Struct
        attribute :message, Types::Strict::String
      end

      class Forbidden < Dry::Struct
        attribute :message, Types::Strict::String
      end

      class Conflict < Dry::Struct
        attribute :message, Types::Strict::String
        attribute :debug_message, Types::Strict::String
      end

      class NotAcceptable < Dry::Struct
        attribute :message, Types::Strict::String
        attribute :debug_message, Types::Strict::String
      end

      class UnsupportedMediaType < Dry::Struct
        attribute :message, Types::Strict::String
        attribute :debug_message, Types::Strict::String
      end

      class RequestEntityTooLarge < Dry::Struct
        attribute :message, Types::Strict::String
      end
    end
  end
end
