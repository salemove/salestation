require 'spec_helper'

describe Salestation::Web::Responses::Success do
  subject(:create_success) { described_class.new(attributes) }

  let(:attributes) { {status: status, body: body} }
  let(:status) { 200 }

  context 'when body is a hash' do
    let(:body) { {key: 'value'} }

    it 'has status' do
      expect(create_success.status).to eq(status)
    end

    it 'has body' do
      expect(create_success.body).to eq(body)
    end
  end

  context 'when body is an array' do
    let(:body) { [{foo: 'bar'}, {foo: 'baz'}] }

    it 'has status' do
      expect(create_success.status).to eq(status)
    end

    it 'has body' do
      expect(create_success.body).to eq(body)
    end
  end

  describe '.with_code' do
    let(:body) { {key: 'value'} }

    it 'creates success with provided code' do
      expect(described_class.with_code(201).new(attributes).status)
        .to eq(201)
    end
  end
end
