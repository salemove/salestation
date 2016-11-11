module Salestation
  module Web
    module ErrorMapper
      ERROR_TO_RESPONSE = {
        App::Errors::InvalidInput => -> (error) {
          Responses::UnprocessableEntityFromSchemaErrors.create(error)
        },
        App::Errors::DependencyCurrentlyUnavailable => -> (error) {
          Responses::ServiceUnavailable.new(
            message: error.message,
            debug_message: "Please try again later"
          )
        }
      }.freeze

      def self.map
        -> (error) do
          _, error_mapper = ERROR_TO_RESPONSE
            .find {|error_type, _| error.kind_of?(error_type) }

          # Interpret a Failure from the application layer as Success in the web
          # layer. Even if the domain specific operation failed, the web layer is
          # still able to successfully produce a well-formed response.
          if error_mapper
            Deterministic::Result::Success(error_mapper.call(error))
          elsif error.is_a?(Hash)
            Deterministic::Result::Success(Responses::InternalError.new(error))
          else
            raise "Unknown error #{error.class.name}"
          end
        end
      end
    end
  end
end
