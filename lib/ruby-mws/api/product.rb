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
            response.product.map { |p| p.attribute_sets.item_attributes }
          end
        ]
    end
  end
end
