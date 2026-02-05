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
  let(:middleware) { described_class.new(web_app, statsd, metric: 'test.req') }

  describe '#call' do
    it 'records status and status class' do
      expect(statsd).to receive(:distribution)
        .with(
          'test.req',
          instance_of(Float),
          tags: include('status:204', 'status_class:2xx')
        )

      middleware.call(status: 204)
    end

    context 'origin tagging' do

      context 'with origin header containing glia.com domains' do
        it 'tags glia.com origin as origin:glia' do
          expect(statsd).to receive(:distribution)
            .with('test.req', instance_of(Float), tags: include('origin:glia'))
          middleware.call(status: 200, 'HTTP_ORIGIN' => 'https://glia.com')
        end

        it 'tags app.glia.com origin as origin:glia' do
          expect(statsd).to receive(:distribution)
            .with('test.req', instance_of(Float), tags: include('origin:glia'))
          middleware.call(status: 200, 'HTTP_ORIGIN' => 'https://app.glia.com')
        end

        it 'tags www.glia.com origin as origin:glia' do
          expect(statsd).to receive(:distribution)
            .with('test.req', instance_of(Float), tags: include('origin:glia'))
          middleware.call(status: 200, 'HTTP_ORIGIN' => 'http://www.glia.com')
        end
      end

      context 'with origin header containing non-glia domains' do
        it 'tags example.com origin as origin:other' do
          expect(statsd).to receive(:distribution)
            .with('test.req', instance_of(Float), tags: include('origin:other'))
          middleware.call(status: 200, 'HTTP_ORIGIN' => 'https://example.com')
        end

        it 'tags notglia.com origin as origin:other' do
          expect(statsd).to receive(:distribution)
            .with('test.req', instance_of(Float), tags: include('origin:other'))
          middleware.call(status: 200, 'HTTP_ORIGIN' => 'https://notglia.com')
        end
      end

      context 'with Referer fallback' do
        it 'tags glia.com Referer as origin:glia when origin is missing' do
          expect(statsd).to receive(:distribution)
            .with('test.req', instance_of(Float), tags: include('origin:glia'))
          middleware.call(status: 200, 'HTTP_REFERER' => 'https://glia.com/page')
        end

        it 'tags external.com Referer as origin:other when origin is missing' do
          expect(statsd).to receive(:distribution)
            .with('test.req', instance_of(Float), tags: include('origin:other'))
          middleware.call(status: 200, 'HTTP_REFERER' => 'https://external.com')
        end
      end

      context 'with origin taking precedence over Referer' do
        it 'uses origin when both headers are present' do
          expect(statsd).to receive(:distribution)
            .with('test.req', instance_of(Float), tags: include('origin:glia'))
          middleware.call(
            status: 200,
            'HTTP_ORIGIN' => 'https://glia.com',
            'HTTP_REFERER' => 'https://other.com'
          )
        end
      end

      context 'with missing headers' do
        it 'tags as origin:other when both headers are missing' do
          expect(statsd).to receive(:distribution)
            .with('test.req', instance_of(Float), tags: include('origin:other'))
          middleware.call(status: 200)
        end
      end

      context 'with edge cases' do
        it 'handles glia.com with port as origin:glia' do
          expect(statsd).to receive(:distribution)
            .with('test.req', instance_of(Float), tags: include('origin:glia'))
          middleware.call(status: 200, 'HTTP_ORIGIN' => 'https://glia.com:3000')
        end

        it 'handles case insensitive matching for GLIA.COM as origin:glia' do
          expect(statsd).to receive(:distribution)
            .with('test.req', instance_of(Float), tags: include('origin:glia'))
          middleware.call(status: 200, 'HTTP_ORIGIN' => 'https://GLIA.COM')
        end

        it 'tags malformed URL as origin:other' do
          expect(statsd).to receive(:distribution)
            .with('test.req', instance_of(Float), tags: include('origin:other'))
          middleware.call(status: 200, 'HTTP_ORIGIN' => 'not a url')
        end

        it 'prevents false positive for glia.com.evil.com as origin:other' do
          expect(statsd).to receive(:distribution)
            .with('test.req', instance_of(Float), tags: include('origin:other'))
          middleware.call(status: 200, 'HTTP_ORIGIN' => 'https://glia.com.evil.com')
        end
      end
    end
  end
end
