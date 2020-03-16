# frozen_string_literal: true
require_relative '../thread_accessors.rb'

module Salestation
  module ActiveRecordStats
    class Collector
      extend ThreadAccessors

      thread_mattr_accessor :runtime, :queries

      def initialize(statsd, prefix:)
        @statsd = statsd
        @prefix = prefix
      end

      def subscribe
        ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          process(event)
        end
      end

      def emit(tags:)
        @statsd.batch do |statsd|
          statsd.histogram("#{@prefix}.runtime", runtime, tags: tags)
          statsd.histogram("#{@prefix}.queries", queries, tags: tags)
        end
      end

      def reset
        self.runtime = 0.0
        self.queries = 0
      end

      private

      def process(event)
        self.runtime += event.duration
        self.queries += 1
      end
    end
  end
end
