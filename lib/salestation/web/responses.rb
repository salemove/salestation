# frozen_string_literal: true

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

      def self.to_no_content
        -> (*) { Deterministic::Result::Success(Responses::NoContent.new(body: {})) }
      end

      class Response < Dry::Struct
        def self.with_code(code)
          Class.new(self) do
            define_singleton_method :new do |attrs|
              super(attrs.merge(status: code))
            end
          end
        end
      end

      class Error < Response
        attribute :status, Types::Strict::Integer
        attribute? :message, Types::String.optional
        attribute? :debug_message, Types::Coercible::String.default('')
        attribute :context, Types::Hash.default({}.freeze)
        attribute :headers, Types::Hash.default({}.freeze)
        attribute? :base_error, Types::Coercible::Hash

        def body
          # Merge into `base_error` to ensure standard fields are not overriden
          merge_not_nil(base_error || {}, :message, message)
            .merge(debug_message: debug_message)
        end

        private

        def merge_not_nil(map, key, value)
          map[key] = value if value
          map
        end
      end

      class UnprocessableEntityError < Error
        attribute? :form_errors, Types::Coercible::Hash.optional

        def body
          super.merge({form_errors: form_errors}.compact)
        end
      end

      class Success < Response
        attribute :status, Types::Strict::Integer
        attribute :body, Types::Strict::Hash | Types::Strict::Array
        attribute :headers, Types::Hash.default({}.freeze)
      end

      class UnprocessableEntityFromSchemaErrors
        def self.create(errors:, hints:, base_error: nil, form_errors: false)
          message = errors ? parse_errors(errors) : nil
          debug_message = hints ? parse_hints(hints) : nil

          UnprocessableEntity.new(
            message: message,
            debug_message: debug_message,
            form_errors: form_errors ? errors : nil,
            base_error: base_error
          )
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
      NotAcceptable = Error.with_code(406)
      Conflict = Error.with_code(409)
      RequestEntityTooLarge = Error.with_code(413)
      UnsupportedMediaType = Error.with_code(415)
      UnprocessableEntity = UnprocessableEntityError.with_code(422)

      InternalError = Error.with_code(500)
      ServiceUnavailable = Error.with_code(503)
    end
  end
end
