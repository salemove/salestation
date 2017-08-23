require 'spec_helper'

rack_request = Class.new do
  def initialize(env_data)
    @env = env_data
  end
  attr_reader :env
end

describe Salestation::Web::Extractors::BodyParamExtractor do
  subject(:extract_body_params) { described_class[*options].call(request) }

  let(:request) { rack_request.new('rack.request.form_hash' => params) }
  let(:options) { %i[first_key second_key] }

  context 'when body params exist' do
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

  context 'with coercions' do
    let(:params) do
      {
        'first_key' => 'first value',
        'second_key' => 'second value'
      }
    end

    let(:expected_result) do
      {
        first_key: 'new first value',
        second_key: 'second value'
      }
    end

    let(:coercions) { {first_key: ->(first_key) { 'new ' + first_key }} }
    let(:options) { [:first_key, :second_key, {coercions: coercions}] }

    it 'coerces param' do
      result = extract_body_params

      expect(result).to be_a(Deterministic::Result::Success)
      expect(result.value).to eq(expected_result)
    end
  end
end
