# frozen_string_literal: true

require 'rspec/expectations'

module Salestation
  module RSpec
    class FailureMatcher
      include ::RSpec::Matchers::Composable

      attr_reader :expected, :actual, :failure_message

      def initialize
        @contents_matchers = []
      end

      def with(error_class)
        @error_class = error_class
        self
      end

      # From: active_support/inflector/methods.rb
      def self.underscore(camel_cased_word)
        return camel_cased_word unless /[A-Z-]|::/.match?(camel_cased_word)
        word = camel_cased_word.to_s.gsub("::", "/")
        word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
        word.tr!("-", "_")
        word.downcase!
        word
      end
      private_class_method :underscore

      # Defined methods using error class names:
      #   with_conflict
      #   with_invalid_input
      #   ...
      Salestation::App::Errors.constants.each do |class_name|
        define_method(:"with_#{underscore(class_name.to_s)}") do
          with(Salestation::App::Errors.const_get(class_name))
          self
        end
      end

      def containing(matcher)
        @contents_matchers << matcher
        self
      end

      def matches?(actual)
        check_failure(actual) &&
          check_error_type(actual) &&
          check_contents(actual)
      end

      def diffable?
        true
      end

      private

      def check_failure(actual)
        return true if actual.class == Deterministic::Result::Failure

        @failure_message = "Expected Failure(...), but got #{actual.inspect}"
        @expected = Deterministic::Result::Failure
        @actual = actual.class
        false
      end

      def check_error_type(actual)
        return true unless @error_class
        return true if actual.value.class == @error_class

        @failure_message = "Expected failure to include #{@error_class}, but got #{actual.value.inspect}"
        @expected = @error_class
        @actual = actual.value.class
        false
      end

      def check_contents(actual)
        return true if @contents_matchers.empty?

        has_error = @contents_matchers.detect do |contents_matcher|
          if contents_matcher.is_a?(Hash) || rspec_matcher?(contents_matcher)
            verify_contents_using_regular_matcher!(contents_matcher, actual)
          else
            verify_contents_using_base_error!(contents_matcher, actual)
          end
        end

        !has_error
      end

      # Returns true when error was detected
      def verify_contents_using_regular_matcher!(contents_matcher, actual)
        return false if values_match?(contents_matcher, actual.value.to_h)

        @failure_message = "Contents in #{actual.value.class} do not match"
        @expected = contents_matcher
        @actual = actual.value.to_h

        true
      end

      # Returns true when error was detected
      def verify_contents_using_base_error!(contents_matcher, actual)
        # Compare hashes if possible, otherwise expect it to respond to `#matches?`.
        contents_matcher = contents_matcher.to_h if contents_matcher.respond_to?(:to_h)

        return false if values_match?(contents_matcher, actual.value[:base_error])

        @failure_message = "Expected failure to be based on #{contents_matcher}, but got #{actual.value.inspect}"
        @expected = contents_matcher
        @actual = actual.value[:base_error].to_h

        true
      end

      def rspec_matcher?(matcher)
        # Didn't find a better way to detect matchers like HashIncludingMatcher
        matcher.class.to_s.start_with?('RSpec')
      end
    end
  end
end
