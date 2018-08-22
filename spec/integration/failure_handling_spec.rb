require 'spec_helper'

describe 'Failure handling' do
  let(:custom_error_class) { Class.new(StandardError) }
  let(:custom_error_response) { double(body: custom_response, status: 200, headers: headers) }
  let(:custom_response) { {custom: 'response'} }
  let(:headers) { {'X-Custom-Header' => 'Value'} }

  before do
    stub_const('CustomErrorClass', custom_error_class)
    stub_const('CustomErrorResponse', custom_error_response)
  end

  it 'supports customer error mapping' do
    web_app = Class.new do
      include Salestation::Web.new(errors: {
        CustomErrorClass => -> (error) { CustomErrorResponse }
      })

      def json(input)
        input.to_json
      end

      def run
        app = Salestation::App.new(env: {})
        to_error = -> (request) { request.to_failure(CustomErrorClass.new) }
        chain = -> (request) { request >> to_error }
        process(chain.call(app.create_request({})))
      end

      def status(*); end

      def headers(*); end
    end

    app = web_app.new
    allow(app).to receive(:headers)

    response = app.run
    expect(response).to eq(JSON.dump(custom_response))

    expect(app).to have_received(:headers).with(headers)
  end
end
