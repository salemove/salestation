require 'spec_helper'

rack_request = Class.new do
  def initialize(env_data)
    @env = env_data
  end
  attr_reader :env
end

describe Salestation::Web::Extractors::HeadersExtractor do
  context 'when header exists' do
    value = 'custom value'
    request = rack_request.new(
      'HTTP_X_CUSTOM_HEADER' => value
    )

    it 'extracts header from request and assigns to specified key' do
      result = extract_headers(request, 'x-custom-header' => :custom_key)

      expect(result).to be_a(Deterministic::Result::Success)
      expect(result.value).to eq(custom_key: value)
    end
  end

  context 'when header does not exist' do
    request = rack_request.new({})

    it 'does not include the key in the extracted response' do
      result = extract_headers(request, 'x-custom-header' => :custom_key)

      expect(result).to be_a(Deterministic::Result::Success)
      expect(result.value).to eq({})
    end
  end

  def extract_headers(rack_request, headers)
    described_class[headers].call(rack_request)
  end
end
