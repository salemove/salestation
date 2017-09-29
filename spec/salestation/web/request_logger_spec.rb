require 'spec_helper'

describe Salestation::Web::RequestLogger do
  class Webapp
    def call(env)
      [200, {}, [{ 'key' => 'value' }.to_json]]
    end
  end

  let(:web_app) { Webapp.new }
  let(:logger) { double(:info) }

  before do
    allow(logger).to receive(:info)
  end

  describe '#call' do
    it 'logs response body' do
      expect(logger).to receive(:info).with(
        'Processed request',
        a_hash_including(body: { 'key' => 'value' })
      )
      described_class.new(web_app, logger).call({})
    end

    it 'does not log response body when response body logging is disabled' do
      described_class.new(web_app, logger, log_response_body: false).call({})

      expect(logger).to have_received(:info).with(
        'Processed request',
        hash_excluding(body: anything)
      )
    end
  end
end
