module MWS
  module API

    class Product < Base
      def_request [:get_matching_product, :get_matching_product_by_next_token],
      :verb => :get,
      :uri => '/Products/2011-10-01',
      :version => '2011-10-01',
      :lists => {
        :asin => "ASINList.ASIN"
      }
    end
  end
end
