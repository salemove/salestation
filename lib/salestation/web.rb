require 'deterministic'
require 'dry-struct'
require 'dry-types'

module Salestation
  module Web
    module Types
      include Dry::Types.module
    end

    def process(response)
      result = response.map_err(&ErrorMapper.map).value

      status result.status
      json JSON.dump(result.body)
    end

    def create_request(env, input)
      App::Request.create(env: env, input: input)
    end
  end
end

require_relative './web/responses'
require_relative './web/error_mapper'
