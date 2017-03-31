$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "salestation"
require 'pry'
require_relative './salestation/support/hook_mock'

class Hash
  def except(*keys)
    reject {|key, val| keys.include?(key) }
  end
end
