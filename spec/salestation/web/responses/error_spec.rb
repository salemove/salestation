require 'spec_helper'

describe Salestation::Web::Responses::Error do
  subject(:create_error) { described_class.new(attributes) }
  let(:attributes) { all_attributes }

  let(:all_attributes) do
    {
      status: status,
      message: message,
      debug_message: debug_message,
      context: context,
      headers: headers
    }
  end
  let(:status) { 200 }
  let(:message) { 'message' }
  let(:debug_message) { 'debug message' }
  let(:context) { {foo: 'bar'} }
  let(:headers) { {'X-Custom-Header' => 'Value'} }

  it 'has status' do
    expect(create_error.status).to eq(status)
  end

  it 'has message' do
    expect(create_error.message).to eq(message)
  end

  it 'has debug_message' do
    expect(create_error.debug_message).to eq(debug_message)
  end

  it 'has context' do
    expect(create_error.context).to eq(context)
  end

  it 'has message and debug_message in body' do
    expect(create_error.body).to eql(message: message, debug_message: debug_message)
  end

  it 'has headers' do
    expect(create_error.headers).to eq(headers)
  end

  context 'when debug message is missing' do
    let(:attributes) { all_attributes.except(:debug_message) }

    it 'defaults to empty string' do
      expect(create_error.debug_message).to eq('')
    end
  end

  context 'when context is missing' do
    let(:attributes) { all_attributes.except(:context) }

    it 'defaults to empty hash' do
      expect(create_error.context).to eq({})
    end
  end

  context 'when headers are missing' do
    let(:attributes) { all_attributes.except(:headers) }

    it 'defaults to empty hash' do
      expect(create_error.headers).to eq({})
    end
  end

  describe '.with_code' do
    it 'creates error with provided code' do
      expect(described_class.with_code(500).new(attributes).status)
        .to eq(500)
    end
  end
end
