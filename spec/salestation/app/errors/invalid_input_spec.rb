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

  context '.from' do
    let(:base_error) { {details: 'details'} }

    it 'creates error with base error, errors and hints' do
       invalid_input = described_class.from(base_error, errors: errors, hints: hints)

       expect(invalid_input.errors).to eql(errors)
       expect(invalid_input.hints).to eql(hints)
       expect(invalid_input.base_error).to eql(base_error)
    end

    context 'when base error is not hash' do
      class BaseError
        def to_h
          {details: 'details2'}
        end
      end

      it 'converts base error to hash' do
        invalid_input = described_class.from(BaseError.new, errors: errors, hints: hints)
        expect(invalid_input.base_error).to eql(BaseError.new.to_h)
      end
    end
  end
end
