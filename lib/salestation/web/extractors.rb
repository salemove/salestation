# frozen_string_literal: true
require "symbolizer"

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

        def rename(rules)
          InputRenamer.new(self, rules)
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
      #  extractor = Salestation::Web::Extractors::BodyParamExtractor[:x, :y]
      #    .coerce(x: ->(value) { "x_#{value}"})
      #  input = {
      #   'x' => 'a',
      #   'y' => 'b',
      #  }
      #  # rack_request is Rack::Request with 'rack.request.form_hash' set to input
      #  extractor.call(rack_request(input)).value
      #  #=> {x: 'x_a', y: 'b'}
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

      # Handles renaming input keys
      #
      # When renaming we want to ensure that the new key provided for the rename does not already
      # exist in the input. When it does and it has a not nil value, then rename will not happen,
      # unless `override: true` is also applied. When the new key exists with nil value,
      # rename will happen.
      # By default override is set to false: when input already has value set for the new key,
      # the old key will be discarded instead of overwriting the value.
      # For deprecating (renaming for deprecation purposes), one should extract both new and old key
      # from the input before calling the rename function, to get expected result, as only then the
      # values can be compared in rename.
      #
      # @example
      #  input = {
      #    'x' => 'a',
      #    'y' => 'b'
      #  }
      #
      #  extractor = Salestation::Web::Extractors::BodyParamExtractor[:x, :y]
      #    .rename(x: :z)
      #  extractor.call(rack_request(input)).value
      #  #=> {z: 'a', y: 'b'}
      #
      #  extractor = Salestation::Web::Extractors::BodyParamExtractor[:x, :y]
      #    .rename(x: :y)
      #  extractor.call(rack_request(input)).value
      #  #=> {y: 'b'}
      #
      #  extractor = Salestation::Web::Extractors::BodyParamExtractor[:x, :y]
      #    .rename(x: {new_key: :y, override: true})
      #  extractor.call(rack_request(input)).value
      #  #=> {y: 'a'}
      class InputRenamer
        def initialize(extractor, rules)
          @extractor = extractor
          @rules = map_rules(rules)
        end

        def call(rack_request)
          @extractor
            .call(rack_request)
            .map(&method(:rename))
        end

        def rename(input)
          @rules.each do |old_key, rule|
            new_key = rule[:new_key]
            override = rule[:override]

            if input[new_key].nil? || override
              input[new_key] = input[old_key]
            end

            input.delete(old_key)
          end
          Deterministic::Result::Success(input)
        end

        private

        def map_rules(rules)
          rules.map do |field, rule|
            [field, rule.is_a?(Hash) ? rule : {new_key: rule, override: false}]
          end.to_h
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
          # Filter as a hash is used in some existing implementations that did not expect full 
          # recursive symbolizing of keys. In this case hash objects at the highest level of object 
          # are represented as hash of filter keys. This is no longer needed, but we support it 
          # to avoid a breaking change.

          filters_flat = filters
                          .flat_map {|filter| filter.is_a?(Hash) ? filter.keys : filter}
                          .map(&:to_s)

          request_hash = request_hash.select {|k,v| filters_flat.include?(k)}

          Symbolizer.symbolize(request_hash)
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
      #  extractor = Salestation::Web::Extractors::BodyParamExtractor[:x, :y, {foo: [:bar, :baz]}, :aaa]
      #  input = {
      #   'x' => '1',
      #   'y' => '2',
      #   'z' => '3',
      #   'foo' => {
      #     'bar' => 'qq'
      #    },
      #   'aaa' => [
      #      {
      #        'bb' => 'cc'
      #      }
      #    ]
      #  }
      #  # rack_request is Rack::Request with 'rack.request.form_hash' set to input
      #  extractor.call(rack_request(input)).value
      #  #=> {x: '1', y: '2', foo: {bar: 'qq'}, aaa: [{bb: 'cc'}]}
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
