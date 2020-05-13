# frozen_string_literal: true

require 'deterministic'
require 'dry-struct'
require 'dry-types'

module Salestation
  class App
    module Types
      include Dry::Types()
    end

    def initialize(env:, hooks: {})
      @environment = env
      @hook_listeners = {}
      @hooks = hooks
    end

    def start
      @hooks.each do |hook_type, hook|
        hook.start_listening do |payload|
          @hook_listeners.fetch(hook_type, []).each { |handle| handle.call(payload) }
        end
      end
    end

    def create_request(input, span: nil)
      Request.create(
        env: @environment,
        input: input,
        initialize_hook: method(:initialize_hook),
        span: span
      )
    end

    def register_listener(hook_type, listener)
      @hook_listeners[hook_type] ||= []
      @hook_listeners[hook_type].push(listener)
    end

    private

    def initialize_hook(hook_type, payload)
      raise "Unknown hook_type #{hook_type}" unless @hooks[hook_type]

      @hooks[hook_type].init(payload)
    end
  end
end

require_relative './app/errors'
require_relative './app/request'
require_relative './app/input_verification'
require_relative './result_helper'
