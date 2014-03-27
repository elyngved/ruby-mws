require 'spec_helper'

describe MWS::API::Order do

  before :all do
    EphemeralResponse.activate
  end

  context "requests" do
    let (:mws) {MWS.new(auth_params)}

    describe "list_orders" do
      it "should receive a list of orders" do
        orders = mws.orders.list_orders :last_updated_after => "2012-01-15T13:07:26-05:00" ,
          :timestamp => timestamp
        orders.orders.should be_an_instance_of Array
        orders.orders.first.should have_key :amazon_order_id
      end
    end

    describe "list_orders_by_next_token" do
      it "should receive a list_orders_by_next_token_result" do
        orders = mws.orders.list_orders_by_next_token :timestamp => timestamp,
          :next_token => "zwR7fTkqiKp/YYuZQbKv1QafEPREmauvizt1MIhPYZZl3LSdPSOgN1byEfyVqilNBpcRD1uxgRxTg2dsYWmzKd8ytOVgN7d/KyNtf5fepe2OEd7gVZif6X81/KsTyqd1e64rGQd1TyCS68vI7Bqws+weLxD7b1CVZciW6QBe7o2FizcdzSXGSiKsUkM4/6QGllhc4XvGqg5e0zIeaOVNezxWEXvdeDL7eReo//Hc3LMRF18hF5ZYNntoCB8irbDGcVkxA+q0fZYwE7+t4NjazyEZY027dXAVTSGshRBy6ZTthhfBGj6Dwur8WCwcU8Vc25news0zC1w6gK1h3EdXw7a3u+Q12Uw9ZROnI57RGr4CrtRODNGKSRdGvNrxcHpI2aLZKrJa2MgKRa+KsojCckrDiHqb8mBEJ88g6izJN42dQcLTGQRwBej+BBOOHYP4"
        orders.orders.should be_an_instance_of Array
        orders.orders.first.should have_key :amazon_order_id
      end
    end

    describe "get_order" do
      it "should return one order for one order id" do
        order = mws.orders.get_order :amazon_order_id => "102-4850183-7065809",
          :timestamp => timestamp
        order.should have_key :orders
        order.orders.should be_an_instance_of Array
        order.orders.first.should have_key :amazon_order_id
      end

      it "should return multiple orders for multiple order ids" do
        orders = mws.orders.get_order :amazon_order_id => ["102-4850183-7065809", "002-3400187-5292203"],
          :timestamp => timestamp
        orders.orders.should be_an_instance_of Array
        orders.orders.size.should == 2
        orders.orders.first.should have_key :amazon_order_id
      end
    end

    describe "list_order_items" do
      it "should return a list of items for an order" do
        order = mws.orders.list_order_items :amazon_order_id => "102-4850183-7065809",
          :timestamp => timestamp
        order.should have_key :amazon_order_id
        order.should have_key :order_items
        order.order_items.should be_an_instance_of Array
      end
    end

    describe "list_order_items_by_next_token" do
    end

    describe "callback block" do
      let(:response_callback) {double("response_callback", :call => nil)}
      let(:request_callback) {double("request_callback", :call => nil)}
      let(:mws) {MWS.new(auth_params.merge(:response_callback => response_callback,
                                           :request_callback => request_callback))}
      let(:order_id) {
        # just grab one order id
        # if this doesn't work most things will fail
        orders = mws.orders.list_orders :last_updated_after => "2012-01-15T13:07:26-05:00"
        orders.orders.first.amazon_order_id
      }

      it "should be called on list order items" do
        expect(response_callback).to receive(:call)
        expect(request_callback).to receive(:call)        
        mws.orders.list_order_items :amazon_order_id => order_id
      end

      it "should be called on list orders" do
        expect(response_callback).to receive(:call)
        expect(request_callback).to receive(:call)
        mws.orders.list_orders :last_updated_after => "2012-01-15T13:07:26-05:00"
      end

      it "should be called on list order items" do 
        expect(response_callback).to receive(:call)
        expect(request_callback).to receive(:call)
        mws.orders.list_order_items :amazon_order_id => order_id
      end
    end
  end
end
