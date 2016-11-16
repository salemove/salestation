require 'spec_helper'

describe Salestation::App::Errors::InvalidInput do
  subject(:create_invalid_input) { described_class.new(attributes) }
  let(:attributes) { all_attributes }

  let(:all_attributes) { {errors: errors, hints: hints} }
  let(:errors) { {x: 'y'} }
  let(:hints) { {foo: 'bar'} }

  it 'has errors' do
    expect(create_invalid_input.errors).to eq(errors)
  end

  it 'has hints' do
    expect(create_invalid_input.hints).to eq(hints)
  end

  context 'when hints not provided' do
    let(:attributes) { all_attributes.except(:hints) }

    it 'defaults to an empty hash' do
      expect(create_invalid_input.hints).to eq({})
    end
  end
end
