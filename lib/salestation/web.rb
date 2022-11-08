# frozen_string_literal: true

require 'deterministic'
require 'dry-struct'
require 'dry-types'
require 'json'

module Salestation
  class Web < Module
    module Types
      dry_types_version = Gem.loaded_specs['dry-types'].version
      if dry_types_version < Gem::Version.new('0.15.0')
        include Dry::Types.module
      else
        include Dry::Types()
      end
    end

    def initialize(errors: {})
      @error_mapper = ErrorMapper.new(errors)
    end

    def included(base)
      error_mapper = @error_mapper

      base.class_eval do
        const_set :Responses, Salestation::Web::Responses

        define_method(:process) do |response|
          result =
            if response.value.is_a?(Salestation::Web::Responses::Response)
              response.value
            else
              response.map_err(error_mapper.map).value
            end

          status result.status
          headers result.headers
          json result.body
        end
      end
    end
  end
end

require_relative './web/extractors'
require_relative './web/ip_address'
require_relative './web/responses'
require_relative './web/error_mapper'
require_relative './result_helper'
require_relative './web/active_record_connection_management'
require_relative './web/request_logger'
require_relative './web/statsd_middleware'
require_relative './web/input_validator'
require_relative './web/input_validators/accept_header'
require_relative './web/input_validators/content_type_header'
