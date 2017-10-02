module Salestation
  class App
    module Errors
      class InvalidInput < Dry::Struct
        constructor_type :strict_with_defaults

        attribute :errors, Types::Strict::Hash
        attribute :hints, Types::Coercible::Hash.default({})
      end

      class DependencyCurrentlyUnavailable < Dry::Struct
        constructor_type :strict

        attribute :message, Types::Strict::String
      end

      class RequestedResourceNotFound < Dry::Struct
        constructor_type :strict

        attribute :message, Types::Strict::String
      end

      class Forbidden < Dry::Struct
        constructor_type :strict

        attribute :message, Types::Strict::String
      end

      class Conflict < Dry::Struct
        constructor_type :strict

        attribute :message, Types::Strict::String
        attribute :debug_message, Types::Strict::String
      end
    end
  end
end
