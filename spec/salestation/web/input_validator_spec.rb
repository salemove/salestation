# frozen_string_literal: true

require 'spec_helper'

describe Salestation::Web::InputValidator do
  subject(:validate_headers) do
    described_class[
      first_key: ->(value) do
        if value == 'expected'
          Deterministic::Result::Success(nil)
        else
          Deterministic::Result::Failure(Salestation::App::Errors::UnsupportedMediaType.new(
            message: 'Unsupported Content-Type Header',
            debug_message: ''
          ))
        end
      end,
      second_key: ->(value) do
        if value == 'expected'
          Deterministic::Result::Success(nil)
        else
          Deterministic::Result::Failure(Salestation::App::Errors::NotAcceptable.new(
            message: 'Unsupported Accept Header',
            debug_message: ''
          ))
        end
      end,
    ].call(params)
  end

  let(:params) do
    {
      first_key: first_key_value,
      second_key: second_key_value
    }
  end

  let(:first_key_value) { 'expected' }
  let(:second_key_value) { 'expected' }

  context 'when all keys pass validation' do
    let(:first_key_value) { 'expected' }

    it 'returns success' do
      expect(validate_headers).to be_success
      expect(validate_headers.value).to eq(params)
    end
  end

  context 'when one key fails validation' do
    let(:first_key_value) { 'unexpected' }

    it 'returns error' do
      expect(validate_headers.value).to be_a(Salestation::App::Errors::UnsupportedMediaType)
    end
  end

  context 'when all keys fail validation' do
    let(:first_key_value) { 'unexpected' }
    let(:second_key_value) { 'unexpected' }

    it 'returns first error' do
      expect(validate_headers.value).to be_a(Salestation::App::Errors::UnsupportedMediaType)
    end
  end
end
