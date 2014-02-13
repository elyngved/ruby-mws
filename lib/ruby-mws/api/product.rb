module MWS
  module API
    class Product < Base
      def_request [:get_matching_product],
        verb: :get,
        uri: '/Products/2011-10-01',
        version: '2011-10-01',
        mods: [
          lambda do |response|
            response.map! do |p|
              n = p.product.attribute_sets.item_attributes
              n.asin = p.asin
              n
            end
          end
        ]

      def_request [:get_competitive_pricing_for_ASIN],
        verb: :get,
        uri: '/Products/2011-10-01',
        version: '2011-10-01',
        mods: [
          lambda do |response|
            response.map! do |p|
              n = p.product.competitive_pricing
              n.prices = n.competitive_prices.competitive_price
              n.sales_rankings = p.product.sales_rankings
              n.asin = p.asin
              n
            end
          end
        ]

      def_request [:get_lowest_offer_listings_for_ASIN],
        verb: :get,
        uri: '/Products/2011-10-01',
        version: '2011-10-01',
        mods: [
          lambda do |response|
            response.map! do |p|
              n = p.product.lowest_offer_listings
              n.asin = p.asin
              n
            end
          end
        ]

      def_request [:get_product_categories_for_ASIN],
        verb: :get,
        uri: '/Products/2011-10-01',
        version: '2011-10-01'
    end
  end
end
