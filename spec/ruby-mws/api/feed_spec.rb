require 'spec_helper'

describe MWS::API::Feed do

  before :all do
    EphemeralResponse.activate
  end

  context "requests" do
    let(:mws) {@mws = MWS.new(auth_params)}
    let(:first_order_id) {'105-8268075-6520231'}
    let(:second_order_id) {'105-8268075-6520232'}
    let(:order_ack_order_id){'105-1063273-7151427'}
    let(:fulfillment_date){DateTime.now}
    let(:carrier_code){'UPS'}
    let(:shipping_method){'2nd Day'}
    let(:tracking_number){'123321123321'}
    let(:first_item_code){'27030690916666'}
    let(:second_item_code){'62918663121794'}
    let(:third_item_code){'27030690916662'}
    let(:fourth_item_code){'62918663121792'}
    let(:shipment_hash) {
      {
        :fulfillment_date => fulfillment_date,
        :orders => [ {
                       :amazon_order_id => first_order_id,
                       :shipping_method => shipping_method,
                       :carrier_code => carrier_code,
                       :tracking_number => tracking_number,
                       :items => [
                                  {
                                    :amazon_order_item_code => first_item_code,
                                    :quantity => 1
                                  },
                                  {
                                    :amazon_order_item_code => second_item_code,
                                    :quantity => 1
                                  }
                                 ]
                     },{
                       :amazon_order_id => second_order_id,
                       :shipping_method => shipping_method,
                       :carrier_code => carrier_code,
                       :items => [
                                  {
                                    :amazon_order_item_code => third_item_code,
                                    :quantity => 1,
                                    :merchant_order_item_id => 11
                                  },
                                  {
                                    :amazon_order_item_code => fourth_item_code,
                                    :quantity => 1,
                                    :merchant_order_item_id => 12
                                  }
                                 ]
                     } ]
      }
    }
    let(:merchant_order_id){"10"}
    let(:merchant_order_item_code){"123"}
    let(:amazon_order_item_code){"10-31-123123"}
    let(:order_hash){{
      :amazon_order_id => order_ack_order_id,
      :merchant_order_id => merchant_order_id,
      :amazon_order_item_code => amazon_order_item_code,
      :merchant_order_item_id => merchant_order_item_code
    }}
    let(:product_hash_list) {
      {
          :purge_and_replace => false,
          :entries => [ product_hash_1, product_hash_2 ]
      }
    }
    let(:five_taggings) {{:taggings=>[{:tag_name=>"layne mcdonald"}, {:tag_name=>"how the man became the moon"}, {:tag_name=>"team work"}, {:tag_name=>"kindness to others"}, {:tag_name=>"friendship"}]}}
    let(:without_taggings) {{:taggings=>[]}}

    let(:product_hash_1) {
      {
        :message_id => 1,
        :operation_type => 'Update',
        :isbn => first_item_code,
        :item_condition_type => 'New',
        :item_package_quantity => 1,
        :number_of_items => 1,
        :title => 'The Hobbit 1',
        :brand => 'Blurb',
        :description => 'The Hobbit 2, or There and Back Again is a fantasy novel.',
        :unit_of_measure => 'IN',
        :package_length => 14,
        :package_width => 12,
        :package_height => 1,
        :currency => 'USD',
        :standard_price => '290',
        :manufacturer => 'Blurb',
        :search_terms => five_taggings,
        :authors => 'J. R. R. Tolkien',
        :binding => 'Hardcover',
        :publication_date => '2014-01-31T11:03:11',
        :pages => 100
      }
    }

    let(:product_hash_2) {
      {
          :message_id => 2,
          :operation_type => 'Update',
          :isbn => second_item_code,
          :item_condition_type => 'New',
          :item_package_quantity => 1,
          :number_of_items => 1,
          :title => 'The Hobbit 2',
          :brand => 'Blurb',
          :description => 'The Hobbit 2, or There and Back Again is a fantasy novel.',
          :unit_of_measure => 'IN',
          :package_length => 11,
          :package_width => 6,
          :package_height => 2,
          :currency => 'USD',
          :standard_price => '390',
          :manufacturer => 'Blurb',
          :search_terms => without_taggings,
          :authors => 'J. R. R. Tolkien',
          :binding => 'Hardcover',
          :publication_date => '2016-01-31T11:03:11',
          :pages => 111
      }
    }

    describe "submit_feed" do
      it "should be able to ack an order" do
        response = mws.feeds.submit_feed(MWS::API::Feed::ORDER_ACK, order_hash)
        response.feed_submission_info.should_not be_nil

        info = response.feed_submission_info
        info.feed_processing_status.should == "_SUBMITTED_"
        info.feed_type.should == MWS::API::Feed::ORDER_ACK
      end

      it "should create the correctx body for an order" do
        MWS::API::Feed.should_receive(:post) do |uri, hash|
          hash.should include(:body)
          body = hash[:body]
          body_doc = Nokogiri.parse(body)
          body_doc.css('AmazonEnvelope MessageType').text.should == "OrderAcknowledgement"
          body_doc.css('AmazonEnvelope Message OrderAcknowledgement').should_not be_empty
          body_doc.css('AmazonEnvelope Message OrderAcknowledgement AmazonOrderID').text.should == order_ack_order_id
          body_doc.css('AmazonEnvelope Message OrderAcknowledgement MerchantOrderID').text.should == merchant_order_id
          body_doc.css('AmazonEnvelope Message OrderAcknowledgement StatusCode').text.should == "Success"
          body_doc.css('AmazonEnvelope Message OrderAcknowledgement Item').should_not be_empty
          body_doc.css('AmazonEnvelope Message OrderAcknowledgement Item AmazonOrderItemCode').text.should == amazon_order_item_code
          body_doc.css('AmazonEnvelope Message OrderAcknowledgement Item MerchantOrderItemID').text.should == merchant_order_item_code
          body_doc.css('AmazonEnvelope Message OrderAcknowledgement Item Quantity').each do |quantity|
            quantity.text.should == "1"
          end
          
        end
        
        response = mws.feeds.submit_feed(MWS::API::Feed::ORDER_ACK, order_hash)
      end

      it "should be able to ack a shipment" do
        response = mws.feeds.submit_feed(MWS::API::Feed::SHIP_ACK, shipment_hash)
        response.feed_submission_info.should_not be_nil

        info = response.feed_submission_info
        info.feed_processing_status.should == "_SUBMITTED_"
        info.feed_type.should == MWS::API::Feed::SHIP_ACK
      end

      it "should create the correct body for shipment" do
        MWS::API::Feed.should_receive(:post) do |uri, hash|
          hash.should include(:body)
          body = hash[:body]
          
          body_doc = Nokogiri.parse(body)
          ids = body_doc.css('AmazonEnvelope Message OrderFulfillment AmazonOrderID')

          ids.should_not be_empty
          ids[0].text.should == first_order_id
          ids[1].text.should == second_order_id


          body_doc.css('AmazonEnvelope MessageType').length.should == 1 # multiple types was causing problems
          body_doc.css('AmazonEnvelope Message OrderFulfillment').should_not be_empty
          body_doc.css('AmazonEnvelope Message OrderFulfillment AmazonOrderID').should_not be_empty
          body_doc.css('AmazonEnvelope Message OrderFulfillment FulfillmentDate').first.text.should == fulfillment_date.to_s
          body_doc.css('AmazonEnvelope Message OrderFulfillment FulfillmentData').should_not be_empty
          body_doc.css('AmazonEnvelope Message OrderFulfillment FulfillmentData CarrierCode').first.text.should == carrier_code
          body_doc.css('AmazonEnvelope Message OrderFulfillment FulfillmentData ShippingMethod').first.text.should == shipping_method
          body_doc.css('AmazonEnvelope Message OrderFulfillment FulfillmentData ShipperTrackingNumber').count.should == 1
          body_doc.css('AmazonEnvelope Message OrderFulfillment FulfillmentData ShipperTrackingNumber').first.text.should == tracking_number

          body_doc.css('AmazonEnvelope Message Item').should_not be_empty
          body_doc.css('AmazonEnvelope Message Item AmazonOrderItemCode')[0].text.should == first_item_code
          body_doc.css('AmazonEnvelope Message Item AmazonOrderItemCode')[1].text.should == second_item_code
          body_doc.css('AmazonEnvelope Message Item AmazonOrderItemCode')[2].text.should == third_item_code
          body_doc.css('AmazonEnvelope Message Item AmazonOrderItemCode')[3].text.should == fourth_item_code
        end
        response = mws.feeds.submit_feed(MWS::API::Feed::SHIP_ACK, shipment_hash)
      end

      it 'should be able to ack the product' do
        response = mws.feeds.submit_feed(MWS::API::Feed::PRODUCT_LIST, product_hash_list)
        response.feed_submission_info.should_not be_nil
        info = response.feed_submission_info
        info.feed_processing_status.should == "_SUBMITTED_"
        info.feed_type.should == MWS::API::Feed::PRODUCT_LIST
      end

      it "should create the correct body for product" do
        MWS::API::Feed.should_receive(:post) do |uri, hash_list|
          hash_list.should include(:body)
          body = hash_list[:body]
          body_doc = Nokogiri.parse(body)

          ids = body_doc.css('AmazonEnvelope Message Product SKU')
          ids.should_not be_empty
          ids[0].text.should == first_item_code
          ids[1].text.should == second_item_code

          body_doc.css('AmazonEnvelope MessageType').length.should == 1 # multiple types was causing problems
          body_doc.css('AmazonEnvelope PurgeAndReplace').text.should == "false"
          body_doc.css('AmazonEnvelope Message Product').should_not be_empty
          body_doc.css('AmazonEnvelope Message Product SKU').should_not be_empty
          body_doc.css('AmazonEnvelope Message Product StandardProductID Value')[0].text.should == first_item_code
          body_doc.css('AmazonEnvelope Message Product Condition ConditionType')[0].text.should == "New"
          body_doc.css('AmazonEnvelope Message Product DescriptionData Title')[0].text.should == "The Hobbit 1"
          body_doc.css('AmazonEnvelope Message Product DescriptionData Title')[1].text.should == "The Hobbit 2"
          body_doc.css('AmazonEnvelope Message Product DescriptionData Manufacturer')[0].text.should == "Blurb"
          body_doc.css('AmazonEnvelope Message Product DescriptionData MSRP')[0].text.should == "290"
          body_doc.css('AmazonEnvelope Message Product DescriptionData MSRP')[1].text.should == "390"
          body_doc.css('AmazonEnvelope Message Product DescriptionData MSRP').first.attributes["currency"].value.should == "USD"
          pp body_doc.css('AmazonEnvelope Message Product DescriptionData SearchTerms')
          pp body_doc.css('AmazonEnvelope Message Product DescriptionData SearchTerms')[0]
          pp body_doc.css('AmazonEnvelope Message Product DescriptionData SearchTerms')[1]
          body_doc.css('AmazonEnvelope Message Product DescriptionData SearchTerms').length.should == 5
          body_doc.css('AmazonEnvelope Message Product DescriptionData SearchTerms').first.text.should == "layne mcdonald"
          body_doc.css('AmazonEnvelope Message Product DescriptionData SearchTerms').last.text.should == "friendship"
          body_doc.css('AmazonEnvelope Message Product DescriptionData PackageDimensions Length')[0].text.should == "14"
          body_doc.css('AmazonEnvelope Message Product DescriptionData PackageDimensions Width')[0].text.should == "12"
          body_doc.css('AmazonEnvelope Message Product DescriptionData PackageDimensions Height')[0].text.should == "1"
          body_doc.css('AmazonEnvelope Message Product DescriptionData PackageDimensions Length').first.attributes["unitOfMeasure"].value.should == "IN"
          body_doc.css('AmazonEnvelope Message Product ProductData Books ProductType Author')[0].text.should == "J. R. R. Tolkien"
          body_doc.css('AmazonEnvelope Message Product ProductData Books ProductType Binding')[0].text.should == "Hardcover"
        end
        response = mws.feeds.submit_feed(MWS::API::Feed::PRODUCT_LIST, product_hash_list)
      end

    end
    
    describe "callback block" do
      let(:response_callback) {double("response_callback", :call => nil)}
      let(:request_callback) {double("request_callback", :call => nil)}      
      let(:mws) {MWS.new(auth_params.merge(:response_callback => response_callback,
                                           :request_callback => request_callback))}

      it "should be called on list order items" do
        expect(response_callback).to receive(:call)
        expect(request_callback).to receive(:call)
        response = mws.feeds.submit_feed(MWS::API::Feed::ORDER_ACK, {
                                           :amazon_order_id => '105-1063273-7151427'
                                         })

      end
    end
  end
end