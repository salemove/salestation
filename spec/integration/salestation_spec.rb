require 'spec_helper'

describe 'Salestation' do
  it 'supports extracting input using Extractors module' do
    web_app = Class.new do
      include Salestation::Web.new
      APP = Salestation::App.new(env: {})

      def json(input)
        input.to_json
      end

      def status(*); end

      def create_app_request(input)
        Salestation::App.new(env: {}).create_request(input)
      end

      def run
        sinatra_request = Object.new
        chain = ->(request) { Deterministic::Result::Success(request.input) }
        extractor =
          Salestation::Web::Extractors::ConstantInput[foo1: 'bar1']
          .merge(Salestation::Web::Extractors::ConstantInput[foo2: 'bar2'])

        process(
          extractor.call(sinatra_request)
            .map { |input| create_app_request(input) }
            .map(chain)
            .map(Salestation::Web::Responses.to_ok)
        )
      end
    end

    result = web_app.new.run
    expect(result).to eq('{"foo1":"bar1","foo2":"bar2"}')
  end

  it 'shows input error when unable to extract input using an extractor' do
    web_app = Class.new do
      include Salestation::Web.new

      def json(input)
        input.to_json
      end

      def status(*); end

      def create_app_request
        lambda do |input|
          Salestation::App.new(env: {}).create_request(input)
        end
      end

      def run
        sinatra_request = Object.new
        chain = ->(request) { Deterministic::Result::Success(request.input) }
        extractor = lambda do |_request|
          Deterministic::Result::Failure(
            Salestation::Web::Responses::Unauthorized.new(message: 'unauthorized')
          )
        end

        process(
          extractor.call(sinatra_request)
            .map(create_app_request)
            .map(chain)
            .map(Salestation::Web::Responses.to_ok)
        )
      end
    end

    result = web_app.new.run
    expect(result).to eq('{"message":"unauthorized","debug_message":""}')
  end
end
