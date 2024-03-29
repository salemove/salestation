require 'spec_helper'

describe Salestation::Web::ErrorMapper do
  context 'when using a custom defined error' do
    let(:custom_error_class) { Class.new(StandardError) }
    let(:custom_response_class) { Class.new }

    let(:error_mapper) do
      Salestation::Web::ErrorMapper.new({
        custom_error_class => -> (error) { custom_response_class.new }
      })
    end

    it 'returns custom error' do
      response = Salestation::App::Request.new(env: {}, input: {})
        .to_failure(custom_error_class.new)
        .map_err(&error_mapper.map)
        .value

      expect(response).to be_a(custom_response_class)
    end
  end

  context 'when Errors::Forbidden' do
    let(:error_mapper) { Salestation::Web::ErrorMapper.new }
    let(:message) { 'no access' }

    it 'returns Responses::Forbidden' do
      response = Salestation::App::Request.new(env: {}, input: {})
        .to_failure(Salestation::App::Errors::Forbidden.new(message: message))
        .map_err(&error_mapper.map)
        .value

      expect(response).to be_a(Salestation::Web::Responses::Forbidden)
    end
  end

  context 'when Errors::Conflict' do
    let(:error_mapper) { Salestation::Web::ErrorMapper.new }
    let(:message) { 'conflict' }
    let(:debug_message) { 'fix conflict' }

    it 'returns Responses::Conflict' do
      response = Salestation::App::Request.new(env: {}, input: {})
        .to_failure(Salestation::App::Errors::Conflict.new(message: message, debug_message: debug_message))
        .map_err(&error_mapper.map)
        .value

      expect(response).to be_a(Salestation::Web::Responses::Conflict)
    end
  end

  context 'when Errors::NotAcceptable' do
    let(:error_mapper) { Salestation::Web::ErrorMapper.new }
    let(:message) { 'not acceptable' }
    let(:debug_message) { 'unsupported accept header' }

    it 'returns Responses::NotAcceptable' do
      response = Salestation::App::Request.new(env: {}, input: {})
        .to_failure(Salestation::App::Errors::NotAcceptable.new(message: message, debug_message: debug_message))
        .map_err(&error_mapper.map)
        .value

      expect(response).to be_a(Salestation::Web::Responses::NotAcceptable)
    end
  end

  context 'when Errors::UnsupportedMediaType' do
    let(:error_mapper) { Salestation::Web::ErrorMapper.new }
    let(:message) { 'unsupported media type' }
    let(:debug_message) { 'unsupported content type' }

    it 'returns Responses::UnsupportedMediaType' do
      response = Salestation::App::Request.new(env: {}, input: {})
        .to_failure(Salestation::App::Errors::UnsupportedMediaType.new(message: message, debug_message: debug_message))
        .map_err(&error_mapper.map)
        .value

      expect(response).to be_a(Salestation::Web::Responses::UnsupportedMediaType)
    end
  end

  context 'when Errors::RequestEntityTooLarge' do
    let(:error_mapper) { Salestation::Web::ErrorMapper.new }
    let(:message) { 'request entity too large' }

    it 'returns Responses::RequestEntityTooLarge' do
      response = Salestation::App::Request.new(env: {}, input: {})
        .to_failure(Salestation::App::Errors::RequestEntityTooLarge.new(message: message))
        .map_err(&error_mapper.map)
        .value

      expect(response).to be_a(Salestation::Web::Responses::RequestEntityTooLarge)
    end
  end

  context 'when Errors::BadRequest' do
    let(:error_mapper) { Salestation::Web::ErrorMapper.new }
    let(:message) { 'invalid request message framing' }

    it 'returns Responses::BadRequest' do
      response = Salestation::App::Request.new(env: {}, input: {})
        .to_failure(Salestation::App::Errors::BadRequest.new(message: message))
        .map_err(&error_mapper.map)
        .value

      expect(response).to be_a(Salestation::Web::Responses::BadRequest)
    end
  end

  context 'when undefined error class' do
    let(:error_mapper) { Salestation::Web::ErrorMapper.new }

    it 'throws UndefinedErrorClass exception' do
      expect {
        Salestation::App::Request.new(env: {}, input: {})
          .to_failure(StandardError.new)
          .map_err(&error_mapper.map)
      }.to raise_error(described_class::UndefinedErrorClass)
    end
  end
end
