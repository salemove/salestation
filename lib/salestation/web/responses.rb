module Salestation
  class Web < Module
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
          message = parse_errors(errors)
          debug_message = parse_hints(hints)

          UnprocessableEntity.new(message: message, debug_message: debug_message)
        end

        def self.parse_errors(errors)
          parsed_errors = errors.map do |field, error_messages|
            if error_messages.is_a?(Hash)
              errors_with_nested_keys = error_messages.keys.map do |key|
                { "#{field}.#{key}" => error_messages[key] }
              end

              parse_errors(errors_with_nested_keys.reduce(Hash.new, :merge))
            else
              "'#{field}' #{error_messages.join(' and ')}"
            end
          end
          parsed_errors.join(". ")
        end

        def self.parse_hints(hints)
          parsed_hints = hints.select { |field, hint_messages| hint_messages.any? }
            .map do |field, hint_messages|
              if hint_messages.is_a?(Hash)
                hints_with_nested_keys = hint_messages.keys.map do |key|
                  { "#{field}.#{key}" => hint_messages[key] }
                end

                parse_hints(hints_with_nested_keys.reduce(Hash.new, :merge))
              else
                "'#{field}' #{hint_messages.join(' and ')}"
              end
            end
          parsed_hints.join(". ")
        end
      end

      OK = Success.with_code(200)
      Created = Success.with_code(201)
      Accepted = Success.with_code(202)
      NoContent = Success.with_code(204)

      Unauthorized = Error.with_code(401)
      Forbidden = Error.with_code(403)
      NotFound = Error.with_code(404)
      UnprocessableEntity = Error.with_code(422)

      InternalError = Error.with_code(500)
      ServiceUnavailable = Error.with_code(503)
    end
  end
end
