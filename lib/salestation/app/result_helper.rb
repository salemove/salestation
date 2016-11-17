module Salestation
  class App
    module ResultHelper
      def observe(&block)
        -> (result_value) do
          block.call(result_value)
          Deterministic::Result::Success(result_value)
        end
      end

      def empty_success_response
        -> (request) do
          Deterministic::Result::Success({})
        end
      end
    end
  end
end
