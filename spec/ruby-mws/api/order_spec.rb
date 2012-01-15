require 'spec_helper'

describe MWS::API::Order do

  before :all do
    EphemeralResponse.activate
    @mws = MWS.new(auth_params)
    @timestamp = "2012-01-15T17:28:17-05:00"
  end

  context "requests" do
    describe "list_orders" do
      it "should receive a list_orders_result" do
        orders = @mws.orders.list_orders :last_updated_after => "2012-01-15T13:07:26-05:00" ,
          :timestamp => @timestamp
        orders.has_key?('orders').should be_true
        orders.orders.has_key?('order').should be_true
        orders.orders.order.should be_an_instance_of Array
        orders.should == @mws.orders.response.list_orders_response.list_orders_result
      end
    end

    describe "list_orders_by_next_token" do
      it "should receive a list_orders_by_next_token_result" do
        orders = @mws.orders.list_orders_by_next_token :timestamp => @timestamp,
          :next_token => "zwR7fTkqiKp/YYuZQbKv1QafEPREmauvizt1MIhPYZZl3LSdPSOgN1byEfyVqilNBpcRD1uxgRxTg2dsYWmzKd8ytOVgN7d/KyNtf5fepe2OEd7gVZif6X81/KsTyqd1e64rGQd1TyCS68vI7Bqws+weLxD7b1CVZciW6QBe7o2FizcdzSXGSiKsUkM4/6QGllhc4XvGqg5e0zIeaOVNezxWEXvdeDL7eReo//Hc3LMRF18hF5ZYNntoCB8irbDGcVkxA+q0fZYwE7+t4NjazyEZY027dXAVTSGshRBy6ZTthhfBGj6Dwur8WCwcU8Vc25news0zC1w6gK1h3EdXw7a3u+Q12Uw9ZROnI57RGr4CrtRODNGKSRdGvNrxcHpI2aLZKrJa2MgKRa+KsojCckrDiHqb8mBEJ88g6izJN42dQcLTGQRwBej+BBOOHYP4"
        orders.has_key?('orders').should be_true
        orders.orders.has_key?('order').should be_true
        orders.orders.order.should be_an_instance_of Array
      end
    end

    describe "get_order" do
      it "should return one order for one order id" do
        order = @mws.orders.get_order :amazon_order_id => "102-4850183-7065809",
          :timestamp => @timestamp
        order.has_key?('orders').should be_true
        order.orders.has_key?('order').should be_true
        order.orders.order.amazon_order_id.should be
      end

      it "should return multiple orders for multiple order ids" do
        orders = @mws.orders.get_order :amazon_order_id => ["102-4850183-7065809", "002-3400187-5292203"],
          :timestamp => @timestamp
        orders.has_key?('orders').should be_true
        orders.orders.has_key?('order').should be_true
        orders.orders.order.should be_an_instance_of Array
        orders.orders.order.size.should == 2
      end
    end

    describe "list_order_items" do
      it "should return a list of items for an order" do
        order = @mws.orders.list_order_items :amazon_order_id => "102-4850183-7065809",
          :timestamp => @timestamp
        order.has_key?('amazon_order_id').should be_true
        order.has_key?('order_items').should be_true
        order.order_items.has_key?('order_item').should be_true
      end
    end

    describe "list_order_items_by_next_token" do

    end
  end

end