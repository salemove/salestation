require 'spec_helper'

describe Salestation::App do
  let(:hooks) { {} }
  let(:env) { double }
  let(:app) { described_class.new(env: env, hooks: hooks) }

  it 'can be started without hooks' do
    expect { app.start }.not_to raise_error
  end

  context 'with application hooks' do
    let(:hook) { HookMock.new.tap { |hook| allow(hook).to receive(:init) } }

    let(:hooks) { {
      'test-hook' => hook
    } }

    before do
      app.start
    end

    it 'calls init on hook when initializing hook through request' do
      request = app.create_request({}).value
      request.initialize_hook('test-hook', 'hook-setup-payload')
      expect(hook).to have_received(:init).with('hook-setup-payload')
    end

    context 'when listeners registered for hook' do
      let(:listener) { double }

      before do
        app.register_listener('test-hook', listener)
      end

      it 'calls listener when hook is triggered' do
        expect(listener).to receive(:call).with('hook-trigger-payload')
        hook.trigger('hook-trigger-payload')
      end
    end
  end

  describe '#create_request' do
    context 'when span is given' do
      it 'can be accessed' do
        input = {}
        span = double('span')
        request = app.create_request(input, span: span).value
        expect(request.span).to eq(span)
      end
    end

    context 'when span is missing' do
      it 'defaults to nil' do
        input = {}
        request = app.create_request(input).value
        expect(request.span).to be_nil
      end
    end
  end
end
