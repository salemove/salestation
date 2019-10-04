require 'spec_helper'

describe Salestation::App::Errors::DependencyCurrentlyUnavailable do
  subject(:create_dependency_currently_unavailable) { described_class.new(message: message) }

  let(:message) { 'message' }

  it 'has message' do
    expect(create_dependency_currently_unavailable.message).to eq(message)
  end

  context 'when debug_message is provided' do
    subject(:create_dependency_currently_unavailable) do
      described_class.new(message: message, debug_message: debug_message)
    end

    let(:debug_message) { 'something' }

    it 'creates getter for debug_message' do
      expect(create_dependency_currently_unavailable.debug_message).to eq('something')
    end
  end
end
