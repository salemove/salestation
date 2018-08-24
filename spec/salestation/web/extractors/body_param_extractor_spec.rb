require 'spec_helper'

rack_request = Class.new do
  def initialize(env_data)
    @env = env_data
  end
  attr_reader :env
end

describe Salestation::Web::Extractors::BodyParamExtractor do
  let(:request) { rack_request.new('rack.request.form_hash' => params) }

  context 'when body params exist' do
    subject(:extract_body_params) { described_class[:first_key, :second_key].call(request) }

    let(:params) do
      {
        'first_key' => 'first value',
        'second_key' => 'second value'
      }
    end

    let(:expected_result) do
      {
        first_key: 'first value',
        second_key: 'second value'
      }
    end

    it 'extracts body params from request' do
      result = extract_body_params
      expect(result).to be_a(Deterministic::Result::Success)
      expect(result.value).to eq(expected_result)
    end
  end

  context 'when body param is missing' do
    subject(:extract_body_params) { described_class[:first_key, :second_key].call(request) }

    let(:params) do
      {'first_key' => 'first value'}
    end

    let(:expected_result) do
      {first_key: 'first value'}
    end

    it 'does not include the missing key in the extracted response' do
      result = extract_body_params

      expect(result).to be_a(Deterministic::Result::Success)
      expect(result.value).to eq(expected_result)
    end
  end

  context 'with nested keys' do
    subject(:extract_body_params) { described_class[:x, {foo: [:bar]}].call(request) }

    let(:params) { {'x' => 'y', 'foo' => {'bar' => 'baz'}} }
    let(:expected_result) { {x: 'y', foo: {bar: 'baz'}} }

    it 'extracts body params from request' do
      result = extract_body_params

      expect(result).to be_a(Deterministic::Result::Success)
      expect(result.value).to eq(expected_result)
    end
  end
end
