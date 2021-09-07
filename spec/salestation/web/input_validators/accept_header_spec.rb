# frozen_string_literal: true

require 'spec_helper'

describe Salestation::Web::InputValidators::AcceptHeader do
  subject(:validate_header) do
    described_class['application/json'].call(header_value)
  end

  context 'when header is not provided' do
    let(:header_value) { nil }

    it 'returns failure' do
      expect(validate_header).to be_failure
      expect(validate_header.value).to eq(Salestation::App::Errors::NotAcceptable.new(
        message: "Unsupported Accept Header '#{header_value}'",
        debug_message: "Available Accept Headers are application/json"
      ))
    end
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

  context 'when one of the accept mime types is allowed' do
    let(:header_value) { 'application/vnd.salemove.v1+json, application/json' }

    it 'returns success' do
      expect(validate_header).to be_success
    end
  end

  context 'when none of the accept mime types are allowed' do
    let(:header_value) { 'application/csv, text/plain' }

    it 'returns failure' do
      expect(validate_header).to be_failure
    end
  end
end
