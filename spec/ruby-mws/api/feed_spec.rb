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
    end
    
    describe "callback block" do
      let(:response_callback) {double("callback", :call => nil)}
      let(:mws) {MWS.new(auth_params.merge(:response_callback => response_callback))}

      it "should be called on list order items" do
        expect(response_callback).to receive(:call)
        response = mws.feeds.submit_feed(MWS::API::Feed::ORDER_ACK, {
                                           :amazon_order_id => '105-1063273-7151427'
                                         })

      end
    end
  end
end
