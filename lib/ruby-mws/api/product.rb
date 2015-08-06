module MWS
  module API

    class Product < Base
      def_request [:list_matching_products],
        :verb => :get,
        :uri => '/Products/2011-10-01',
        :version => '2011-10-01',
        :mods => [
          lambda {|r| r.products = r.products.product.flatten if r.products}
        ]    

      def_request [:get_matching_product],
        :verb => :get,
        :uri => '/Products/2011-10-01',
        :version => '2011-10-01',
        :lists =>{
          :asin_list => "ASINList.ASIN"
        }

      def_request [:get_matching_product_for_id],
        :verb => :get,
        :uri => '/Products/2011-10-01',
        :version => '2011-10-01',
        :lists =>{
          :id_list => "IdList.Id"
        }
      
    end

  end
end