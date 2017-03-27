require 'deterministic'
require 'dry-struct'
require 'dry-types'
require 'json'

module Salestation
  class Web < Module
    module Types
      include Dry::Types.module
    end

    def initialize(errors: {})
      @error_mapper = ErrorMapper.new(errors)
    end

    def included(base)
      error_mapper = @error_mapper

      base.class_eval do
        const_set :Responses, Salestation::Web::Responses

        define_method(:process) do |response|
          result = response.map_err(error_mapper.map).value

          status result.status
          json JSON.dump(result.body)
        end
      end
    end
  end
end

require_relative './web/responses'
require_relative './web/error_mapper'
require_relative './result_helper'
require_relative './web/request_logger'
require_relative './web/statsd_middleware'
