require 'spec_helper'

describe Salestation::App::Errors::DependencyCurrentlyUnavailable do
  subject(:create_dependency_currently_unavailable) { described_class.new(message: message) }

  let(:message) { 'message' }

  it 'has message' do
    expect(create_dependency_currently_unavailable.message).to eq(message)
  end
end
