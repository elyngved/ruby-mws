module MWS
  module API

    class Product < Base
      def_request [:get_matching_product],
        :verb => :get,
        :uri => '/Products/2011-01-01',
        :version => '2011-01-01',
        :lists => {
          :order_status => "OrderStatus.Status"
        },
        :mods => [
          lambda {|r| r.products = r.products.product if r.products}
        ]
    end
  end
end
