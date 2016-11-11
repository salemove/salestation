module Salestation
  module App
    module InputVerification
      def verify_input(schema)
        -> (request) do
          result = schema.call(request.input)
          if result.success?
            request.replace_input(result.output)
          else
            Deterministic::Result::Failure(
              Errors::InvalidInput.new(errors: result.errors, hints: result.hints)
            )
          end
        end
      end
    end
  end
end
