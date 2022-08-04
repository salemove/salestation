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
        @field_error_messages = {}
      end

      def on(*nested_fields)
        @fields << nested_fields
        self
      end

      def with_type(*types)
        @field_error_types[field_to_key(@fields.last)] = types
        self
      end

      def with_message(*messages)
        @field_error_messages[field_to_key(@fields.last)] = messages
        self
      end

      def matches?(actual)
        @fields.all? do |field|
          check_field_exists(actual, *field) &&
            check_field_error_types(field, actual) &&
            check_field_error_messages(field, actual)
        end
      end

      private

      def check_field_exists(actual, field, *nested_fields)
        actual[:error_details].key?(field) &&
          (
            nested_fields.empty? ||
            actual[:error_details][field].any? do |nested_hash|
              check_field_exists(nested_hash, *nested_fields)
            end
          )
      end

      def check_field_error_types(field, actual)
        return true unless @field_error_types[field_to_key(field)]

        actual_error_types = fetch_field_attribute_nested(actual, :type, *field)
        (@field_error_types[field_to_key(field)] - actual_error_types).empty?
      end

      def check_field_error_messages(field, actual)
        return true unless @field_error_messages[field_to_key(field)]

        actual_error_messages = fetch_field_attribute_nested(actual, :message, *field)
        (@field_error_messages[field_to_key(field)] - actual_error_messages).empty?
      end


      def fetch_field_attribute_nested(actual, attribute, field, *nested_fields)
        if nested_fields.empty?
          actual[:error_details].fetch(field).map { |f| f.fetch(attribute) }
        else
          actual[:error_details][field]
            .lazy
            .map { |error_hash| fetch_field_attribute_nested(error_hash, attribute, *nested_fields) }
            .reject(&:nil?)
            .first
        end
      end

      def field_to_key(fields)
        fields.join('->').to_sym
      end
    end
  end
end
