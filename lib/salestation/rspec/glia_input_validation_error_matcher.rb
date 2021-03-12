# frozen_string_literal: true

require 'rspec/expectations'

module Salestation
  module RSpec
    class GliaInputValidationErrorMatcher
      include ::RSpec::Matchers::Composable

      attr_reader :expected, :actual, :failure_message

      def initialize
        @fields = []
        @field_error_types = {}
      end

      def on(field)
        @fields << field
        self
      end

      def with_type(*types)
        @field_error_types[@fields.last] = types
        self
      end

      def matches?(actual)
        @fields.all? do |field|
          check_field_exists(field, actual) &&
            check_field_error_types(field, actual)
        end
      end

      private

      def check_field_exists(field, actual)
        actual[:error_details].key?(field)
      end

      def check_field_error_types(field, actual)
        return true unless @field_error_types[field]

        actual_error_types = actual[:error_details].fetch(field).map { |f| f.fetch(:type) }

        (@field_error_types[field] - actual_error_types).empty?
      end
    end
  end
end
