module Salestation
  module Web
    module Responses
      def self.to_created
        -> (object) { Deterministic::Result::Success(Responses::Created.new(body: object)) }
      end

      def self.to_accepted
        -> (object) { Deterministic::Result::Success(Responses::Accepted.new(body: object)) }
      end

      def self.to_ok
        -> (object) { Deterministic::Result::Success(Responses::OK.new(body: object)) }
      end

      module Response
        def with_code(code)
          Class.new(self) do
            define_singleton_method :new do |attrs|
              super(attrs.merge(status: code))
            end
          end
        end
      end

      class Error < Dry::Struct
        extend Response
        constructor_type :strict_with_defaults

        attribute :status, Types::Strict::Int
        attribute :message, Types::Strict::String
        attribute :debug_message, Types::String.default('')
        attribute :context, Types::Hash.default({})

        def body
          {message: message, debug_message: debug_message}
        end
      end

      class Success < Dry::Struct
        extend Response
        constructor_type :strict

        attribute :status, Types::Strict::Int
        attribute :body, Types::Strict::Hash
      end

      class UnprocessableEntityFromSchemaErrors
        def self.create(errors:, hints:)
          message = errors
            .map { |field, error_messages| "'#{field}' #{error_messages.join(' and ')}" }
            .join(". ")

          debug_message = hints
            .select {|field, hint_messages| hint_messages.any? }
            .map { |field, hint_messages| "'#{field}' #{hint_messages.join(' and ')}" }
            .join(". ")

          UnprocessableEntity.new(message: message, debug_message: debug_message)
        end
      end

      OK = Success.with_code(200)
      Created = Success.with_code(201)
      Accepted = Success.with_code(202)

      Unauthorized = Error.with_code(401)
      UnprocessableEntity = Error.with_code(422)

      InternalError = Error.with_code(500)
      ServiceUnavailable = Error.with_code(503)
    end
  end
end
