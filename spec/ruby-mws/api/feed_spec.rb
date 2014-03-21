require 'spec_helper'

describe MWS::API::Feed do

  before :all do
    EphemeralResponse.activate
  end

  context "requests" do
    let(:mws) {@mws = MWS.new(auth_params)}

    describe "submit_feed" do
      it "should be able to ack an order" do
        response = mws.feeds.submit_feed(MWS::API::Feed::ORDER_ACK, {
                                            :amazon_order_id => '105-1063273-7151427',
                                            :merchant_order_id => 10
                                          })
        response.feed_submission_info.should_not be_nil

        info = response.feed_submission_info
        info.feed_processing_status.should == "_SUBMITTED_"
        info.feed_type.should == MWS::API::Feed::ORDER_ACK
      end

      it "should be able to ack a shipment" do
        response = mws.feeds.submit_feed(MWS::API::Feed::SHIP_ACK, {
                                            :orders => [ {
                                              :amazon_order_id => '105-8268075-6520231',
                                              :merchant_order_id => 10,
                                              :shipping_method => '2nd Day',
                                              :items => [
                                                         {
                                                           :amazon_order_item_code => '27030690916666',
                                                           :quantity => 1,
                                                           :merchant_order_item_id => 11
                                                         },
                                                        {
                                                           :amazon_order_item_code => '62918663121794',
                                                           :quantity => 1,
                                                           :merchant_order_item_id => 12
                                                         }
                                                        ]
                                            },{
                                              :amazon_order_id => '105-8268075-6520232',
                                              :shipping_method => '2nd Day',
                                              :merchant_order_id => 100,
                                              :items => [
                                                         {
                                                           :amazon_order_item_code => '27030690916662',
                                                           :quantity => 2,
                                                           :merchant_order_item_id => 11
                                                         },
                                                        {
                                                           :amazon_order_item_code => '62918663121792',
                                                           :quantity => 2,
                                                           :merchant_order_item_id => 12
                                                         }
                                                        ]
                                            } ]
                                          })
        response.feed_submission_info.should_not be_nil

        info = response.feed_submission_info
        info.feed_processing_status.should == "_SUBMITTED_"
        info.feed_type.should == MWS::API::Feed::SHIP_ACK
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
