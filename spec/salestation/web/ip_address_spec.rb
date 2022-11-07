# frozen_string_literal: true

require 'spec_helper'

describe Salestation::Web::IPAddress do
  let(:ip_address) do
    described_class
  end

  describe '.extract' do
    it 'returns IP address in X-Forwarded-For header' do
      request = { 'HTTP_X_FORWARDED_FOR' => '1.2.3.4, 4.3.2.1', 'REMOTE_ADDR' => '5.6.7.8' }
      expect(ip_address.extract(request)).to eq('1.2.3.4')
      request = { 'HTTP_X_FORWARDED_FOR' => '1.2.3.4, 4.3.2.1' }
      expect(ip_address.extract(request)).to eq('1.2.3.4')
      request = { 'HTTP_X_FORWARDED_FOR' => '1.2.3.4' }
      expect(ip_address.extract(request)).to eq('1.2.3.4')
    end

    it 'returns IP from REMOTE_ADDR if X-Forwarded-For not present' do
      request = { 'REMOTE_ADDR' => '5.6.7.8' }
      expect(ip_address.extract(request)).to eq('5.6.7.8')
    end
  end
end
