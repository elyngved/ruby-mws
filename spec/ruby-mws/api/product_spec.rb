require 'spec_helper'

describe MWS::API::Order do

  before :all do
    EphemeralResponse.activate
    @mws = MWS.new(auth_params)
  end

  context 'requests' do
    describe 'get_matching_product' do
      it 'should receive a list of products' do
        products = @mws.products.get_matching_product :'ASINList.ASIN.1' => 'B002DYJTVW', :'ASINList.ASIN.2' => 'B0018KVHJO'

        products.should be_an_instance_of Array
        products.first.should have_key :asin
        products.first.should have_key :title
      end
    end

    describe 'get_competitive_pricing_for_ASIN' do
      it 'should recieve competitive pricing for an asin' do
        products = @mws.products.get_competitive_pricing_for_ASIN :'ASINList.ASIN.1' => 'B002DYJTVW', :'ASINList.ASIN.2' => 'B0018KVHJO'

        products.should be_an_instance_of Array
        products.first.should have_key :asin
        products.first.should have_key :prices
      end
    end

    describe 'get_lowest_offer_listings_for_ASIN' do
      it 'should recieve competitive pricing for an asin' do
        products = @mws.products.get_lowest_offer_listings_for_ASIN :'ASINList.ASIN.1' => 'B002DYJTVW', :'ASINList.ASIN.2' => 'B0018KVHJO'

        products.should be_an_instance_of Array
        products.first.should have_key :asin
        products.first.should have_key :lowest_offer_listing
      end
    end

    describe 'get_lowest_offer_listings_for_ASIN' do
      it 'should recieve competitive pricing for an asin' do
        category = @mws.products.get_product_categories_for_ASIN ASIN: 'B002DYJTVW'

        category.self.should have_key :product_category_id
        category.self.should have_key :product_category_name
      end
    end
  end
end
