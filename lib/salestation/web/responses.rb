module Salestation
  module Web
    module Responses
      def self.to_created
        -> (object) { Deterministic::Result::Success(Responses::Created.new(body: object)) }
      end

      def self.to_accepted
        -> (object) { Deterministic::Result::Success(Responses::Accepted.new(body: object)) }
      end

      module Response
        def with_code(code)
          Class.new(self) do
            define_method :initialize do |attrs|
              super(attrs.merge(status: code))
            end
          end
        end
      end

      class Error
        extend Response
        include Virtus.value_object(strict: true)

        values do
          attribute :status, Integer
          attribute :message, String
          attribute :debug_message, String, default: ''
          attribute :context, Hash, default: {}
        end

        def body
          {message: message}
        end
      end

      class Success
        extend Response
        include Virtus.value_object(strict: true)

        values do
          attribute :status, Integer
          attribute :body, Hash
        end
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

      Created = Success.with_code(201)
      Accepted = Success.with_code(202)

      Unauthorized = Error.with_code(401)
      UnprocessableEntity = Error.with_code(422)

      InternalError = Error.with_code(500)
      ServiceUnavailable = Error.with_code(503)
    end
  end
end
