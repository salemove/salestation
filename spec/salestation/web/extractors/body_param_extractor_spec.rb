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
    subject(:extract_body_params) { described_class[:x, {foo: [:bar, {a: [:b]}]}].call(request) }

    let(:params) { {'x' => 'y', 'foo' => {'bar' => 'baz', 'a' => {'b' => 'c'}}} }
    let(:expected_result) { {x: 'y', foo: {bar: 'baz', a: {b: 'c'}}} }

    it 'extracts body params from request' do
      result = extract_body_params

      expect(result).to be_a(Deterministic::Result::Success)
      expect(result.value).to eq(expected_result)
    end

    context 'when nested key is missing from input' do
      let(:params) { {'x' => 'y'} }
      let(:expected_result) { {x: 'y'} }

      it 'does not include missing key in extracted response' do
        result = extract_body_params

        expect(result).to be_a(Deterministic::Result::Success)
        expect(result.value).to eq(expected_result)
      end
    end

    context 'when nested value is nil' do
      let(:params) { {'x' => 'y', 'foo' => nil} }
      let(:expected_result) { {x: 'y', foo: nil} }

      it 'extracts body params from request' do
        result = extract_body_params

        expect(result).to be_a(Deterministic::Result::Success)
        expect(result.value).to eq(expected_result)
      end
    end

    context 'when nested value is empty' do
      let(:params) { {'x' => 'y', 'foo' => {}} }
      let(:expected_result) { {x: 'y', foo: {}} }

      it 'extracts body params from request' do
        result = extract_body_params

        expect(result).to be_a(Deterministic::Result::Success)
        expect(result.value).to eq(expected_result)
      end
    end

    context 'when nested value is not a hash' do
      let(:params) { {'x' => 'y', 'foo' => 'bar' } }
      let(:expected_result) { {x: 'y', foo: 'bar' } }

      it 'extracts body params from request' do
        result = extract_body_params

        expect(result).to be_a(Deterministic::Result::Success)
        expect(result.value).to eq(expected_result)
      end
    end
  end

  context 'with array of hashes' do
    subject(:extract_body_params) { described_class[:x, :webhooks].call(request) }

    let(:params) { {'x' => 'y', 'webhooks' => [ {'foo' => 'bar'} ] } }
    let(:expected_result) { {x: 'y', webhooks: [ {foo: 'bar'} ] } }

    it 'extracts body params from request' do
      result = extract_body_params

      expect(result).to be_a(Deterministic::Result::Success)
      expect(result.value).to eq(expected_result)
    end

    context 'when array is empty' do
      let(:params) { {'x' => 'y', 'webhooks' => [] } }
      let(:expected_result) { {x: 'y', webhooks: [] } }

      it 'extracts body params from request' do
        result = extract_body_params

        expect(result).to be_a(Deterministic::Result::Success)
        expect(result.value).to eq(expected_result)
      end
    end

    context 'when hash is nil' do
      let(:params) { {'x' => 'y', 'webhooks' => [ nil ] } }
      let(:expected_result) { {x: 'y', webhooks: [ nil ] } }

      it 'extracts body params from request' do
        result = extract_body_params

        expect(result).to be_a(Deterministic::Result::Success)
        expect(result.value).to eq(expected_result)
      end
    end

    context 'when hash is empty' do
      let(:params) { {'x' => 'y', 'webhooks' => [ {} ] } }
      let(:expected_result) { {x: 'y', webhooks: [ {} ] } }

      it 'extracts body params from request' do
        result = extract_body_params

        expect(result).to be_a(Deterministic::Result::Success)
        expect(result.value).to eq(expected_result)
      end
    end

    context 'when array is strings' do
      let(:params) { {'x' => 'y', 'webhooks' => [ "foobar" ] } }
      let(:expected_result) { {x: 'y', webhooks: [ "foobar" ] } }

      it 'extracts body params from request' do
        result = extract_body_params

        expect(result).to be_a(Deterministic::Result::Success)
        expect(result.value).to eq(expected_result)
      end
    end
  end
end
