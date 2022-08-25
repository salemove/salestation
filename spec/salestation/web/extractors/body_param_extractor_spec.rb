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

  # As agreed in https://github.com/salemove/salestation/pull/66,
  # only highest level keys will effectively be whitelisted. That is
  # why it is OK to have the 'g' included in the result, although it is
  # not included in 'described_class' filters

  context 'with filters as hashes' do
    subject(:extract_body_params) { described_class[:x, {a: [:b, :c], d: [:e, :f]}].call(request) }

    let(:params) { {'x' => 0, 'a' => { 'b' => 1, 'c' => 2}, 'd' => {'e' => 3, 'f' => 4, 'g' => 5}} }
    let(:expected_result) { {x: 0, a: { b: 1, c: 2}, d: {e: 3, f: 4, g: 5} } }

    it 'extracts body params from request' do
      result = extract_body_params

      expect(result).to be_a(Deterministic::Result::Success)
      expect(result.value).to eq(expected_result)
    end
  end

  context 'with complex nested structure' do
    subject(:extract_body_params) { 
      described_class[:name, :sources, :actions, :context, :post_conditions, :context_conditions, :enabled, :array_of_arrays]
      .call(request) 
    }

    let(:params) { 
      {
        'name' => 'b',
        'sources' => [
          {'id' => 'source-id', 'type' => 'form-filling'},
          {'id' => 'source_id2', 'type' => 'form_filling'}
        ],
        'actions' => [
          {
            'type' => 'set_queues_for_visitor',
            'queue_ids' => [],
            'frequency' => {
              'type' => 'timeframe',
              'filters' => [
                {
                  'max_occurrences' => 3,
                  'timeframe' => 'hour',
                  'some_list' => [
                    'some_key' => 'some_content',
                    'another_hash' => {
                      'a' => 'b'
                    }
                  ]
                },
                {
                  'max_occurrences' => 5,
                  'timeframe' => 'day'
                }
              ]
            }
          }
        ],
        'enabled' => true,
        'context' => { 
          'site_id' => '00000000-0000-0000-0000-000000000000'
        },
        'post_conditions' => [
          {
            'condition1' => 'some condition'
          },
          {
            'condition2' => 'another condition'
          }
        ],
        'context_conditions' => {
          'some_condition' => 'condition for context'
        },
        'array_of_arrays' => [
          [ { 'key1' => 'value1', 'key2' => 'value2' }, { 'key3' => 'value3', 'key4' => 'value4' }],
          [ { 'key5' => 'value5', 'key6' => 'value6' }, { 'key7' => 'value7', 'key8' => 'value8' }]
        ]
      }
    }
    
    let(:expected_result) { 
      { 
        name: 'b',
        sources: [
          {id: 'source-id', type: 'form-filling'},
          {id: 'source_id2', type: 'form_filling'}
        ],
        actions: [
          {
            type: 'set_queues_for_visitor',
            queue_ids: [],
            frequency: {
              type: 'timeframe',
              filters: [
                {
                  max_occurrences: 3,
                  timeframe: 'hour',
                  some_list: [
                    some_key: 'some_content',
                    another_hash: {
                      a: 'b'
                    }
                  ]
                },
                {
                  max_occurrences: 5,
                  timeframe: 'day'
                }
              ]
            }
          }
        ],
        enabled: true,
        context: { 
          site_id: '00000000-0000-0000-0000-000000000000'
        },
        post_conditions: [
          {
            condition1: 'some condition'
          },
          {
            condition2: 'another condition'
          }
        ],
        context_conditions: {
          some_condition: 'condition for context'
        },
        array_of_arrays: [
          [ { key1: 'value1', key2: 'value2' }, { key3: 'value3', key4: 'value4' }],
          [ { key5: 'value5', key6: 'value6' }, { key7: 'value7', key8: 'value8' }]
        ]
      }
    }

    it 'extracts body params from request' do
      result = extract_body_params

      expect(result).to be_a(Deterministic::Result::Success)
      expect(result.value).to eq(expected_result)
    end
  end
end
