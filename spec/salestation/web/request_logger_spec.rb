require 'spec_helper'

describe Salestation::Web::RequestLogger do
  class Webapp
    def call(env)
      status = env.fetch(:status, 200)
      body = env.fetch(:body, '')
      headers = env.fetch(:headers, {})

      [status, headers, [body]]
    end
  end

  let(:web_app) { Webapp.new }
  let(:logger) { double(:info) }

  before do
    allow(logger).to receive(:info)
  end

  describe '#call' do
    context 'when response body logging is enabled' do
      let(:middleware) { described_class.new(web_app, logger, log_response_body: true) }

      it 'logs response body' do
        response = { 'key' => 'value' }.to_json

        expect(logger).to receive(:info).with(
          'Processed request',
          a_hash_including(body: response)
        )

        middleware.call(body: response)
      end
    end

    context 'when response body logging is disabled' do
      let(:middleware) { described_class.new(web_app, logger) }

      it 'does not log response body' do
        expect(logger).to receive(:info).with(
          'Processed request',
          hash_excluding(body: anything)
        )

        middleware.call({})
      end

      it 'logs response body as ERROR when response status is >= 500' do
        error = 'Service unavailable'

        expect(logger).to receive(:error).with(
          'Processed request',
          a_hash_including(error: error)
        )

        middleware.call(status: 503, body: error)
      end

      it 'logs response body as INFO when response status is >= 400' do
        error = 'Bad request'

        expect(logger).to receive(:info).with(
          'Processed request',
          a_hash_including(error: error)
        )

        middleware.call(status: 400, body: error)
      end
    end
  end
end
