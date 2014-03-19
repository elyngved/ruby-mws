require 'spec_helper'

describe MWS::API::Order do

  before :all do
    EphemeralResponse.activate
    @mws = MWS.new(auth_params)
  end

  context "requests" do
    describe "list_matching_products" do
      it "should receive a list of products that match" do
        products = @mws.products.list_matching_products query: "Habermaas"
        products.products.should be_an_instance_of Array
        products.products.first.should have_key :attribute_sets
      end
    end   

    describe "get_matching_product" do
      it "should receive a list of products that match with ASIN" do
        products = @mws.products.get_matching_product asin_list: ["B0012KCLIG","B00000J4XU"]
        products.should be_an_instance_of Array
        products.first.should have_key :asin
        products.first.should have_key :product
      end
    end   

    describe "get_matching_product_for_id" do
      it "should receive a list of products that match with IdType and IdList" do
        products = @mws.products.get_matching_product_for_id id_list: ["B0012KCLIG","B00000J4XU"], id_type: "ASIN"
        products.should be_an_instance_of Array
        products.first.should have_key :id_type
        products.first.should have_key :products
      end
    end   
  end

end