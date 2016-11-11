module Salestation
  module App
    class Request
      def self.create(env:, input:)
        new(env: env, input: input).to_success
      end

      attr_reader :env, :input

      def with_input(input_additions)
        replace_input(input.merge(input_additions))
      end

      def replace_input(new_input)
        self.class.new(env: env, input: new_input).to_success
      end

      def to_success
        Deterministic::Result::Success(self)
      end

      def to_failure(input)
        Deterministic::Result::Failure(input)
      end

      private

      def initialize(env:, input:)
        @env = env
        @input = input
      end
    end
  end
end
