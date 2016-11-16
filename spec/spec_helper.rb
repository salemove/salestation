$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "salestation"

class Hash
  def except(*keys)
    reject {|key, val| keys.include?(key) }
  end
end
