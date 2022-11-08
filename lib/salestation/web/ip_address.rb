# frozen_string_literal: true

module Salestation
  class Web < Module
    module IPAddress
      def self.extract(request)
        if request['HTTP_X_FORWARDED_FOR'].nil?
          request['REMOTE_ADDR']
        else
          request['HTTP_X_FORWARDED_FOR'].split(',').first
        end
      end
    end
  end
end
