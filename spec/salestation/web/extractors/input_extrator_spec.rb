require 'spec_helper'

describe Salestation::Web::Extractors::InputExtractor do
  subject(:input_extractor) { described_class[*request] }

  let(:rack_request) { double }

  context 'when constant contains non-UTF-8 characters' do
    let(:input) { 'Hello World \255' }

    let(:expected_result) { 'Hello World' }

    it 'extracts constant from request' do
      result = constant_input
      binding.pry
      expect(result).to be_a(Deterministic.Result.Success)
      expect(result.value).to eq(expected_result)
    end
  end
end