require_relative './web/responses'
require_relative './web/error_mapper'

module Salestation
  module Web
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
