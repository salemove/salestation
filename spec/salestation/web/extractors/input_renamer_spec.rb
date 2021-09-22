require 'spec_helper'

describe Salestation::Web::Extractors::InputRenamer do
  let(:renamer) { described_class.new(extractor, rules) }
  let(:rack_request) { double }
  let(:extractor) { double }

  before do
    allow(extractor).to receive(:call)
      .with(rack_request)
      .and_return(Deterministic::Result::Success(input))
  end

  context 'when no renaming defined' do
    let(:rules) { {} }
    let(:input) { { foo: 'bar' } }

    it 'returns input' do
      expect(renamer.call(rack_request).value).to eq(input)
    end
  end

  context 'when renames defined' do
    context 'when new_key does not exist' do
      let(:rules) { { foo: :baz } }
      let(:input) { { foo: 'bar' } }
      let(:expected_result) { { baz: 'bar' } }

      it 'returns input with applied renames' do
        expect(renamer.call(rack_request).value).to eq(expected_result)
      end
    end

    context 'when new_key already exists' do
      let(:rules) { { foo: :baz } }

      context 'when new_key has missing value' do
        let(:input) { { foo: 'bar', baz: nil } }
        let(:expected_result) { { baz: 'bar' } }

        it 'returns input with applied renames' do
          expect(renamer.call(rack_request).value).to eq(expected_result)
        end
      end

      context 'when new_key has value' do
        let(:input) { { foo: 'bar', baz: 'value' } }
        let(:expected_result) { { baz: 'value' } }

        it 'returns input without applying renames and discards the original' do
          expect(renamer.call(rack_request).value).to eq(expected_result)
        end
      end

      context 'when new_key has value with override true' do
        let(:rules) { { foo: {new_key: :baz, override: true} } }
        let(:input) { { foo: 'bar', baz: 'value' } }
        let(:expected_result) { { baz: 'bar' } }

        it 'returns input with applied renames, discarding new_keys original value' do
          expect(renamer.call(rack_request).value).to eq(expected_result)
        end
      end
    end
  end
end
