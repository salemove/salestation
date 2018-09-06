require 'spec_helper'

describe Salestation::Web::Extractors::InputCoercer do
  let(:coercer) { described_class.new(extractor, rules) }
  let(:rack_request) { double }
  let(:extractor) { double }

  before do
    allow(extractor).to receive(:call)
      .with(rack_request)
      .and_return(Deterministic::Result::Success(input))
  end

  context 'when no coercions defined' do
    let(:rules) { {} }
    let(:input) { { foo: 'bar' } }

    it 'returns input' do
      expect(coercer.call(rack_request).value).to eq(input)
    end
  end

  context 'when coercions defined' do
    let(:rules) { { foo: ->(value) { "#{value}_coerced" } } }
    let(:input) { { foo: 'bar' } }
    let(:expected_result) { { foo: 'bar_coerced' } }

    it 'returns input with applied coercions' do
      expect(coercer.call(rack_request).value).to eq(expected_result)
    end
  end
end
