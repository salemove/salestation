# frozen_string_literal: true

require 'spec_helper'

describe Salestation::Web::StatsdMiddleware do
  class Webapp
    def call(env)
      status = env.fetch(:status, 200)
      body = env.fetch(:body, '')
      headers = env.fetch(:headers, {})

      [status, headers, [body]]
    end
  end

  let(:web_app) { Webapp.new }
  let(:statsd) { double }

  describe '#call' do
    it 'records status and status class' do
      middleware = described_class.new(web_app, statsd, metric: 'test.req')

      expect(statsd).to receive(:distribution)
        .with(
          'test.req',
          instance_of(Float),
          tags: include('status:204', 'status_class:2xx')
        )

      middleware.call(status: 204)
    end
  end
end
