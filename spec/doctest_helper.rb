# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'salestation'
require 'salestation/rspec'

def rack_request(input)
  rack_request_class = Class.new do
    def initialize(env_data)
      @env = env_data
    end
    attr_reader :env
  end
  rack_request_class.new('rack.request.form_hash' => input)
end
