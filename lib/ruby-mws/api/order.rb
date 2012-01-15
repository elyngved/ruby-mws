module MWS
  module API

    class Order < Base

      def_request [:list_orders, :list_orders_by_next_token,
                   :list_order_items, :list_order_items_by_next_token],
        :verb => :get,
        :uri => '/Orders/2011-01-01',
        :version => '2011-01-01'

      def_request :get_order,
        :verb => :get,
        :uri => '/Orders/2011-01-01',
        :version => '2011-01-01',
        :lists => {
          :amazon_order_id => "AmazonOrderId.Id"
        }
    end

  end
end