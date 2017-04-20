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
