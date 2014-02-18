require 'spec_helper'

describe MWS::API::Feed do

  before :all do
    EphemeralResponse.activate
    @mws = MWS.new(auth_params)
  end

  context "requests" do
    describe "submit_feed" do
      it "should be able to ack an order" do
        response = @mws.feeds.submit_feed(MWS::API::Feed::ORDER_ACK, {
                                            :amazon_order_id => '105-1063273-7151427'
                                          })
        response.feed_submission_info.should_not be_nil

        info = response.feed_submission_info
        info.feed_processing_status.should == "_SUBMITTED_"
        info.feed_type.should == MWS::API::Feed::ORDER_ACK
      end

      it "should be able to ack a shipment" do
        response = @mws.feeds.submit_feed(MWS::API::Feed::SHIP_ACK, {
                                            :amazon_order_id => '105-8268075-6520231',
                                            :shipping_method => '2nd Day',
                                            :items => [
                                                       {
                                                         :amazon_order_item_code => '27030690916666',
                                                         :quantity => 1
                                                       },
                                                      {
                                                         :amazon_order_item_code => '62918663121794',
                                                         :quantity => 1
                                                       }
                                                      ]
                                          })
        response.feed_submission_info.should_not be_nil

        info = response.feed_submission_info
        info.feed_processing_status.should == "_SUBMITTED_"
        info.feed_type.should == MWS::API::Feed::SHIP_ACK
      end
    end
  end
end
