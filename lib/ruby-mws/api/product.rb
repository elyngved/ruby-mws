module MWS
  module API
    class Product < Base
      def_request [:get_matching_product],
        verb: :get,
        uri: '/Products/2011-10-01',
        version: '2011-10-01',
        mods: [
          lambda do |response|
            puts response
            response.products = response.product.map do |p|
              p = p[0]
              response = p[:product][:attribute_sets][:item_attributes]
              response[:asin] = p[:asin]
              response
            end
          end
        ]
    end
  end
end
