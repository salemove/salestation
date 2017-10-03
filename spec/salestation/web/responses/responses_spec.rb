require 'spec_helper'

describe Salestation::Web::Responses do
  describe '.to_no_content' do
    let(:to_no_content) { described_class.to_no_content }

    it 'returns No Content' do
      expect(to_no_content.call).to eq(Deterministic::Result::Success(described_class::NoContent.new(body: {})))
    end
  end
end
