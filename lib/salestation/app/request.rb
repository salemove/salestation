# frozen_string_literal: true

module Salestation
  class App
    class Request
      def self.create(env:, input:, initialize_hook: nil, span: nil)
        new(
          env: env,
          input: input,
          initialize_hook: initialize_hook,
          span: span
        ).to_success
      end

      attr_reader :env, :input, :span

      def with_input(input_additions)
        replace_input(input.merge(input_additions))
      end

      def replace_input(new_input)
        self.class.new(
          env: env,
          input: new_input,
          initialize_hook: @initialize_hook,
          span: span
        ).to_success
      end

      def to_success
        Deterministic::Result::Success(self)
      end

      def to_failure(input)
        Deterministic::Result::Failure(input)
      end

      # Initializes an asynchronous application hook
      #
      # Set a listener on App instance to receive a notification when the
      # asynchronous process completes.
      def initialize_hook(hook, payload)
        @initialize_hook.call(hook, payload)
      end

      private

      def initialize(env:, input:, initialize_hook: nil, span: nil)
        @env = env
        @input = input
        @initialize_hook = initialize_hook
        @span = span
      end
    end
  end
end
