# frozen_string_literal: true

require 'spec_helper'
require 'salestation/web/active_record_stats'
require 'datadog/statsd'

RSpec.describe Salestation::ActiveRecordStats::ConnectionPoolInstrumenter do
  let(:prefix) { 'db.test.pool' }
  let(:connection_pool) { double }
  let(:statsd) { instance_spy(Datadog::Statsd) }

  let(:instrumenter) do
    described_class.new(
      connection_pool: connection_pool,
      statsd: statsd,
      prefix: prefix
    )
  end

  before do
    allow(connection_pool).to receive(:stat).and_return(
      size: 10,
      connections: 1,
      busy: 1,
      dead: 0,
      idle: 0,
      waiting: 0,
      checkout_timeout: 5
    )
    allow(statsd).to receive(:gauge)
  end

  it 'sends DB connection pool metrics as gauges' do
    %i[size connections busy dead idle waiting].each do |metric|
      expect(statsd).to receive(:gauge).with("#{prefix}.#{metric}", an_instance_of(Integer))
    end

    instrumenter.instrument!
  end
end
