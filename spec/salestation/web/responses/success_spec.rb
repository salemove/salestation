require 'spec_helper'

describe Salestation::Web::Responses::Success do
  subject(:create_success) { described_class.new(attributes) }

  let(:attributes) { {status: status, body: body} }
  let(:status) { 200 }
  let(:body) { 'body' }

  it 'has status' do
    expect(create_success.status).to eq(status)
  end

  it 'has body' do
    expect(create_success.body).to eq(body)
  end
end
