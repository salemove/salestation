# frozen_string_literal: true

require 'spec_helper'

describe Salestation::Web::InputValidators::ContentTypeHeader do
  subject(:validate_header) do
    described_class['multipart/form-data'].call(header_value)
  end

  context 'when header is not allowed' do
    let(:header_value) { 'application/xml' }

    it 'returns failure' do
      expect(validate_header).to be_failure
      expect(validate_header.value).to eq(Salestation::App::Errors::UnsupportedMediaType.new(
        message: "Unsupported Content-Type Header '#{header_value}'",
        debug_message: "Available Content-Type Headers are multipart/form-data"
      ))
    end
  end

  context 'when header is allowed' do
    let(:header_value) { 'multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW' }

    it 'returns success' do
      expect(validate_header).to be_success
    end
  end
end
