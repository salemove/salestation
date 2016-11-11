module Salestation
  module App
    module Errors
      class InvalidInput
        include Virtus.value_object(strict: true)

        values do
          attribute :errors, Hash
          attribute :hints, Hash
        end
      end

      class DependencyCurrentlyUnavailable
        include Virtus.value_object(strict: true)

        values do
          attribute :message, String
        end
      end
    end
  end
end
