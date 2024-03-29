# frozen_string_literal: true

module Salestation
  class Web < Module
    class ErrorMapper
      UndefinedErrorClass = Class.new(StandardError)

      ERROR_TO_RESPONSE_DEFAULTS = {
        App::Errors::InvalidInput => -> (error) {
          Responses::UnprocessableEntityFromSchemaErrors.create(**error)
        },
        App::Errors::DependencyCurrentlyUnavailable => -> (error) {
          Responses::ServiceUnavailable.new(
            message: error.message,
            debug_message: "Please try again later",
            base_error: error.base_error
          )
        },
        App::Errors::RequestedResourceNotFound => -> (error) {
          Responses::NotFound.new(message: error.message, debug_message: error.debug_message, base_error: error.base_error)
        },
        App::Errors::Forbidden => -> (error) {
          Responses::Forbidden.new(message: error.message, debug_message: error.debug_message, base_error: error.base_error)
        },
        App::Errors::Conflict => -> (error) {
          Responses::Conflict.new(message: error.message, debug_message: error.debug_message, base_error: error.base_error)
        },
        App::Errors::NotAcceptable => -> (error) {
          Responses::NotAcceptable.new(message: error.message, debug_message: error.debug_message, base_error: error.base_error)
        },
        App::Errors::UnsupportedMediaType => -> (error) {
          Responses::UnsupportedMediaType.new(message: error.message, debug_message: error.debug_message, base_error: error.base_error)
        },
        App::Errors::BadRequest => -> (error) {
          Responses::BadRequest.new(message: error.message, debug_message: error.debug_message, base_error: error.base_error)
        },
        App::Errors::RequestEntityTooLarge => -> (error) {
          Responses::RequestEntityTooLarge.new(message: error.message, debug_message: error.debug_message, base_error: error.base_error)
        }
      }.freeze

      def initialize(map = {})
        @error_to_response_map = ERROR_TO_RESPONSE_DEFAULTS.merge(map)
      end

      def map
        -> (error) do
          _, error_mapper = @error_to_response_map
            .find {|error_type, _| error.kind_of?(error_type) }

          # Interpret a Failure from the application layer as Success in the web
          # layer. Even if the domain specific operation failed, the web layer is
          # still able to successfully produce a well-formed response.
          if error_mapper
            Deterministic::Result::Success(error_mapper.call(error))
          elsif error.is_a?(Hash)
            Deterministic::Result::Success(Responses::InternalError.new(error))
          else
            raise UndefinedErrorClass, "Undefined error class: #{error.class.name}"
          end
        end
      end
    end
  end
end
