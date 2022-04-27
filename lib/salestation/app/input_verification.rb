# frozen_string_literal: true

module Salestation
  class App
    module InputVerification
      def verify_input(schema)
        -> (request) do
          input = request.input
          result = schema.call(input)

          dry_validation_version = Gem.loaded_specs['dry-validation'].version
          if dry_validation_version < Gem::Version.new('1.0')
            Mapper.from_dry_validation_result(result.output, result.errors, custom_error_map)
            if result.success?
              request.replace_input(result.output)
            else
              Deterministic::Result::Failure(
                Errors::InvalidInput.new(errors: result.errors, hints: result.hints)
              )
            end
          elsif dry_validation_version <= Gem::Version.new('1.8')
            if result.success?
              request.replace_input(input)
            else
              Deterministic::Result::Failure(
                Errors::InvalidInput.new(errors: result.errors.to_h, hints: result.hints.to_h)
              )
            end
          else
            raise 'Unsupported dry-validation version'
          end
        end
      end
    end
  end
end
