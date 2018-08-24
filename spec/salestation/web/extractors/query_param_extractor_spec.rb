require 'spec_helper'

rack_request = Class.new do
  def initialize(env_data)
    @env = env_data
  end
  attr_reader :env
end

describe Salestation::Web::Extractors::QueryParamExtractor do
  subject(:extract_query_params) { described_class[*options].call(request) }

  let(:request) { rack_request.new('rack.request.query_hash' => params) }
  let(:options) { %i[first_key second_key] }

  context 'when query strings exists' do
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

    it 'extracts query params from request' do
      result = extract_query_params
      expect(result).to be_a(Deterministic::Result::Success)
      expect(result.value).to eq(expected_result)
    end
  end

  context 'when query string does not exist' do
    let(:params) do
      {'first_key' => 'first value'}
    end

    let(:expected_result) do
      {first_key: 'first value'}
    end

    it 'does not include the missing key in the extracted response' do
      result = extract_query_params

      expect(result).to be_a(Deterministic::Result::Success)
      expect(result.value).to eq(expected_result)
    end
  end
end
