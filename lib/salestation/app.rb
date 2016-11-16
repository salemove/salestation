require 'deterministic'
require 'dry-struct'
require 'dry-types'

module Salestation
  module App
    module Types
      include Dry::Types.module
    end
  end
end

require_relative './app/errors'
require_relative './app/request'
require_relative './app/input_verification'
require_relative './app/result_helper'
