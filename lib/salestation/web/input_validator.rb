# frozen_string_literal: true

module Salestation
  class Web < Module
    class InputValidator
      include Deterministic::Prelude

      def self.[](**validations)
        new(**validations)
      end

      def initialize(**validations)
        @validations = validations
      end

      def call(input)
        @validations.reduce(Deterministic::Result::Success({})) do |result, (key, validation)|
          result.map do
            validation.call(input.fetch(key, nil))
          end
        end.map(->(_) { Deterministic::Result::Success(input) })
      end
    end
  end
end
