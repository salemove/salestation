require 'spec_helper'

describe Salestation::ResultHelper do
  let(:helper) { Class.new.extend(described_class) }

  describe 'observe' do
    it 'calls provided block without changing result' do
      observer = Proc.new { }
      expect(observer).to receive(:call).with('test-value')

      result = Deterministic::Result::Success('test-value')
        .map(helper.observe(&observer))

      expect(result.value).to eql('test-value')
    end
  end
end
