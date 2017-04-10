require 'spec_helper'

describe Salestation::Web do
  class WebApp
    include Salestation::Web.new(errors: {})

    def json(input)
      input.to_json
    end

    def status(*)
    end
  end

  let(:web_app) { WebApp.new }

  describe '#process' do
    context 'when response is success' do
      let(:response_body) { {response: 'response'} }
      let(:response) {
        Salestation::Web::Responses.to_ok.call(response_body)
     }

      it 'returns response body as json' do
        expect(web_app.process(response)).to eql(JSON.dump(response_body))
      end
    end

    context 'when response is failure' do
      let(:response_body) { {message: 'error'} }
      let(:response) {
        Deterministic::Result::Success::Failure(response_body)
      }

      it 'returns error with debug message as json' do
        expect(web_app.process(response)).to eql(JSON.dump(response_body.merge(debug_message: '')))
      end
    end
  end
end
