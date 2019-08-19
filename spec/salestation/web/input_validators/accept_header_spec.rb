# frozen_string_literal: true

require 'spec_helper'

describe Salestation::Web::InputValidators::AcceptHeader do
  subject(:validate_header) do
    described_class['application/json'].call(header_value)
  end

  context 'when header is not allowed' do
    let(:header_value) { 'application/xml' }

    it 'returns failure' do
      expect(validate_header).to be_failure
      expect(validate_header.value).to eq(Salestation::App::Errors::NotAcceptable.new(
        message: "Unsupported Accept Header '#{header_value}'",
        debug_message: "Available Accept Headers are application/json"
      ))
    end
  end

  context 'when header is allowed' do
    let(:header_value) { 'application/json' }

    it 'returns success' do
      expect(validate_header).to be_success
    end
  end
end
