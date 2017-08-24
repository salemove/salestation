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
      end

      class HeadersExtractor
        include Deterministic

        def self.[](headers)
          InputExtractor.new do |rack_request|
            input = headers.map do |header, key|
              value = rack_request.env["HTTP_#{header.upcase.tr('-', '_')}"]
              next if value.nil?
              [key, value]
            end.compact.to_h

            Result::Success(input)
          end
        end
      end

      class ParamExtractor
        include Deterministic

        def self.[](*keys, coercions: {}, rack_key:)
          InputExtractor.new do |rack_request|
            request_hash = rack_request.env[rack_key] || {}

            input = keys
              .select { |key| request_hash.key?(key.to_s) }
              .map { |key| [key, request_hash[key.to_s]] }
              .map { |key, value| coercions.key?(key) ? [key, coercions[key].call(value)] : [key, value] }
              .to_h

            Result::Success(input)
          end
        end
      end

      class QueryParamExtractor
        def self.[](*keys, coercions: {})
          ParamExtractor[*keys, coercions: coercions, rack_key: 'rack.request.query_hash']
        end
      end

      class BodyParamExtractor
        def self.[](*keys, coercions: {})
          ParamExtractor[*keys, coercions: coercions, rack_key: 'rack.request.form_hash']
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
