# frozen_string_literal: true

require 'rspec/expectations'
require 'salestation/app'

require_relative './rspec/failure_matcher'
require_relative './rspec/glia_input_validation_error_matcher'

module Salestation
  module RSpec
    # Usage:
    #
    # In your RSpec configuration first include the matchers:
    #
    #   RSpec.configure do |config|
    #     config.include Salestation::RSpec::Matchers
    #   end
    #
    # Then you can use the matchers like this:
    #
    #   expect(result).to be_failure
    #     .with_conflict
    #     .containing(message: 'Oh noes')
    #
    # or when using Glia Errors:
    #
    #   expect(result).to be_failure
    #     .with_requested_resource_not_found
    #     .containing(Glia::Errors::ResourceNotFoundError.new(resource: :user))
    #
    # or when matching input errors from Glia Errors:
    #
    #   expect(result).to be_failure
    #     .with_invalid_input
    #     .containing(glia_input_validation_error.on(:name).with_type(Glia::Errors::INVALID_VALUE_ERROR))
    #
    # or you could even match multiple input errors at the same time:
    #   expect(result).to be_failure
    #     .with_invalid_input
    #     .containing(
    #       glia_input_validation_error
    #         .on(:name).with_type(Glia::Errors::INVALID_VALUE_ERROR)
    #         .on(:email)
    #         .on(:phone_number).with_type(Glia::Errors::INVALID_FORMAT_ERROR)
    #     )
    #
    # Everything after be_failure is optional. You could also use `.containing`
    # multiple times like this:
    #
    #   expect(result).to be_failure
    #     .containing(Glia::Errors::ResourceNotFoundError.new(resource: :user))
    #     .containing(hash_including(message: 'Overriden message'))
    #
    module Matchers
      def be_failure
        FailureMatcher.new
      end

      def glia_input_validation_error
        GliaInputValidationErrorMatcher.new
      end
    end
  end
end
