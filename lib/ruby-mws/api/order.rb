module MWS
  module API

    class Order < Base

      def_request :list_orders,
        :verb => :get,
        :uri => '/Orders/2011-01-01',
        :version => '2011-01-01',
        :return => lambda { |res| res.list_orders_response.list_orders_result.orders.order }

    end

  end
end