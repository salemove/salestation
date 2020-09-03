require 'spec_helper'

describe Salestation::Web::Responses::UnprocessableEntityFromSchemaErrors do
  subject(:error) { described_class.create(attributes) }
  let(:attributes) { {
    errors: errors,
    hints: hints,
  } }

  let(:errors) { {} }
  let(:hints) { {} }

  context 'error with one message' do
    let(:errors) { {content: ['is missing']} }
    let(:hints) { {content: ['is missing']} }

    it 'parses error message' do
      expect(error.message).to eq("'content' is missing")
    end

    it 'parses error debug message' do
      expect(error.debug_message).to eq("'content' is missing")
    end

    it 'returns error hash' do
      expect(error.form_errors).to eq(errors)
      expect(error.body[:form_errors]).to eq(errors)
    end
  end

  context 'error with multiple messages' do
    let(:errors) { {content: ['is missing', 'is invalid']} }
    let(:hints) { {content: ['is missing', 'is invalid']} }

    it 'parses error message' do
      expect(error.message).to eq("'content' is missing and is invalid")
    end

    it 'parses error debug message' do
      expect(error.debug_message).to eq("'content' is missing and is invalid")
    end

    it 'returns error hash' do
      expect(error.form_errors).to eq(errors)
    end
  end

  context 'error with multiple messages and nested errors' do
    let(:errors) {
      {
        status: ['is missing', 'is invalid'],
        message: {
          'id'=>['is missing'],
          'content'=>['is invalid']
        },
        context: ['is invalid']
      }
    }
    let(:hints) {
      {
        status: ['is missing', 'is invalid'],
        message: {
          'id'=>['is missing'],
          'content'=>['is invalid']
        },
        context: ['is invalid']
      }
    }

    it 'parses error message' do
      expect(error.message).to eq(
        "'status' is missing and is invalid. 'message.id' is missing. 'message.content' is invalid. 'context' is invalid"
      )
    end

    it 'parses debug message' do
      expect(error.debug_message).to eq(
        "'status' is missing and is invalid. 'message.id' is missing. 'message.content' is invalid. 'context' is invalid"
      )
    end

    it 'returns error hash' do
      expect(error.form_errors).to eq(errors)
    end
  end
end
