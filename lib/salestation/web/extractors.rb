# frozen_string_literal: true

module Salestation
  class Web < Module
    module Extractors
      class InputExtractor
        include Deterministic

        def initialize(&block)
          @block = block
        end

        def call(rack_request)
          @block.call(rack_request)
        end

        def merge(other)
          CombinedInputExtractor.new([self, other])
        end

        def coerce(rules)
          InputCoercer.new(self, rules)
        end
      end

      class CombinedInputExtractor
        def initialize(extractors)
          @extractors = extractors
        end

        def compose_seq(fns, input)
          fns.reduce(Deterministic::Result::Success({})) do |result, fn|
            result.map do |previous_value|
              fn.call(input).map do |new_value|
                Deterministic::Result::Success(yield(previous_value, new_value))
              end
            end
          end
        end

        def call(rack_request)
          compose_seq(@extractors, rack_request) do |previous_input, new_input|
            previous_input.merge(new_input)
          end
        end

        def merge(other_extractor)
          CombinedInputExtractor.new(@extractors + [other_extractor])
        end

        def coerce(rules)
          InputCoercer.new(self, rules)
        end
      end

      # Handles coercing input values
      #
      # @example
      #  extractor = BodyParamExtractor[:x, :y]
      #    .coerce(x: ->(value) { "x_#{value}"})
      #  input = {
      #   'x' => 'a',
      #   'y' => 'b',
      #  }
      #  # rack_request is Rack::Request with 'rack.request.form_hash' set to input
      #  extractor.call(rack_request).value #=> {x: 'x_a', y: 'b'}
      class InputCoercer
        def initialize(extractor, rules)
          @extractor = extractor
          @rules = rules
        end

        def call(rack_request)
          @extractor
            .call(rack_request)
            .map(&method(:coerce))
        end

        def coerce(input)
          @rules.each do |field, coercer|
            input[field] = coercer.call(input[field]) if input.key?(field)
          end
          Deterministic::Result::Success(input)
        end

        def merge(other)
          CombinedInputExtractor.new([self, other])
        end
      end

      class HeadersExtractor
        include Deterministic

        def self.[](headers)
          InputExtractor.new do |rack_request|
            input = headers.map do |header, key|
              value = rack_request.env["HTTP_#{header.upcase.tr('-', '_')}"]
              value ||= rack_request.env["#{header.upcase.tr('-', '_')}"]

              next if value.nil?
              [key, value]
            end.compact.to_h

            Result::Success(input)
          end
        end
      end

      class ParamExtractor
        include Deterministic

        def self.[](filters:, rack_key:)
          InputExtractor.new do |rack_request|
            request_hash = rack_request.env[rack_key] || {}
            input = extract(filters, request_hash)
            Result::Success(input)
          end
        end

        def self.extract(filters, request_hash)
          filters.each_with_object({}) do |filter, extracted_data|
            case filter
            when Symbol
              stringified_key = filter.to_s
              extracted_data[filter] = request_hash[stringified_key] if request_hash.key?(stringified_key)
            when Hash
              filter.each do |key, nested_filters|
                stringified_key = key.to_s
                if request_hash.key?(stringified_key)
                  value = request_hash.fetch(stringified_key)
                  extracted_data[key] = value.nil? ? nil : extract(nested_filters, value)
                end
              end
            end
          end
        end
      end

      class QueryParamExtractor
        def self.[](*filters)
          ParamExtractor[filters: filters, rack_key: 'rack.request.query_hash']
        end
      end

      # Extracts and symbolizes params from request body
      #
      # @example
      #  extractor = BodyParamExtractor[:x, :y, {foo: [:bar, :baz]}]
      #  input = {
      #   'x' => '1',
      #   'y' => '2',
      #   'z' => '3',
      #   'foo' => {
      #     'bar' => 'qq'
      #    }
      #  }
      #  # rack_request is Rack::Request with 'rack.request.form_hash' set to input
      #  extractor.call(rack_request).value #=> {x: 1, y: 2, foo: {bar: 'qq}}
      #
      class BodyParamExtractor
        def self.[](*filters)
          ParamExtractor[filters: filters, rack_key: 'rack.request.form_hash']
        end
      end

      class ConstantInput
        include Deterministic

        def self.[](input)
          InputExtractor.new do |**|
            Result::Success(input)
          end
        end
      end
    end
  end
end
