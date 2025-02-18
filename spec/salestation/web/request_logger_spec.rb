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

    context 'when log level is set to debug' do
      let(:middleware) { described_class.new(web_app, logger, level: :debug) }

      it 'logs messages with debug level' do
        expect(logger).to receive(:debug).with(
          'Processed request',
          an_instance_of(Hash)
        )

        middleware.call({})
      end

      it 'logs requests with status code 4xx as info' do
        expect(logger).to receive(:info).with(
          'Processed request',
          an_instance_of(Hash)
        )

        middleware.call(status: 404)
      end

      it 'logs requests with status code 5xx as error' do
        expect(logger).to receive(:error).with(
          'Processed request',
          an_instance_of(Hash)
        )

        middleware.call(status: 500)
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

    it 'logs Glia-Account-Id and Glia-User-Id headers' do
      middleware = described_class.new(web_app, logger)
      account_id = 'account-id'
      user_id = 'user-id'

      expect(logger).to receive(:info).with(
        'Processed request',
        a_hash_including(glia_account_id: account_id, glia_user_id: user_id)
      )

      middleware.call(body: '{}', 'HTTP_GLIA_ACCOUNT_ID' => account_id, 'HTTP_GLIA_USER_ID' => user_id)
    end

    it 'logs arbitrary extra fields set in the env' do
      middleware = described_class.new(web_app, logger)

      expect(logger).to receive(:info).with(
        'Processed request',
        a_hash_including(arbitrary_field: 'example_value')
      )

      middleware.call(body: '{}', 'salestation.request_logger.fields' => { arbitrary_field: 'example_value' })
    end
  end
end
