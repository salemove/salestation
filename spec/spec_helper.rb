$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'salestation'
require 'salestation/rspec'

require 'pry'
require_relative './salestation/support/hook_mock'

class Hash
  def except(*keys)
    reject {|key, val| keys.include?(key) }
  end
end

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.include Salestation::RSpec::Matchers
end
