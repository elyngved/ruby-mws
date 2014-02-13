require 'digest/md5'
require 'tempfile'
require 'iconv'

module MWS
  module API
    class Feed < Base
      ORDER_ACK = '_POST_ORDER_ACKNOWLEDGEMENT_DATA_'
      SHIP_ACK = '_POST_ORDER_FULFILLMENT_DATA_'
      
      # TODO: think about whether we should make this more general
      # for submission back to the author's fork
      def submit_feed(type=nil, content_params={})
        name = :submit_feed
        body = case type
               when ORDER_ACK
                 content_for_ack_with(content_params)
               when SHIP_ACK
                 content_for_ship_with(content_params)
               end
        body = Iconv.conv("iso-8859-1", "UTF8", body)
        query_params = {:feed_type => type}
        options = {
          :verb => :post,
          :uri => '/',
          :version => '2009-01-01'
        }
        params = [default_params(name.to_s), query_params, options, @connection.to_hash].inject :merge
        query = Query.new params
        resp = self.class.post(query.request_uri,
                               :body => body,
                               :headers => {
                                           'Content-MD5' => Base64.encode64(Digest::MD5.digest(body)),
                                           'Content-Type' => 'text/xml; charset=iso-8859-1'
                                           })

        Response.parse resp, name, params
      end

      private
      # opts require amazon_order_item_code and amazon_order_id
      def content_for_ack_with(opts={})
        body = <<-BODY
<?xml version="1.0"?> 
<AmazonEnvelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="amzn-envelope.xsd"> 
<Header> 
<DocumentVersion>1.01</DocumentVersion> 
<MerchantIdentifier>#{@connection.seller_id}</MerchantIdentifier> 
</Header> 
<MessageType>OrderAcknowledgment</MessageType> 
<Message> 
<MessageID>1</MessageID> 
<OrderAcknowledgement> 
<AmazonOrderID>#{opts[:amazon_order_id]}</AmazonOrderID> 
<StatusCode>Success</StatusCode> 
<Item> 
<AmazonOrderItemCode>#{opts[:amazon_order_item_code]}</AmazonOrderItemCode> 
</Item> 
</OrderAcknowledgment> 
</Message> 
</AmazonEnvelope>
BODY
      end

      # Returns a string containing the shipping achnowledgement xml
      #
      # opts is a hash containing
      #  :merchant_order_id - the internal order id
      #  :carrier_code - string representing a shipper code
      #                  possible codes are USPS, UPS, FedEx, DHL,
      #                  Fastway, GLS, GO!, NipponExpress, YamatoTransport
      #                  Hermes Logistik Gruppe, Royal Mail, Parcelforce,
      #                  City Link, TNT, Target, SagawaExpress,
      #                  
      #  :shipping_method - string describing method (i.e. 2nd Day)
      #  :items - an array of hashes with :amazon_order_item_code and
      #           :quantity keys
      #  :tracking_number - (optional) shipper tracking number
      #  :fulfillment_date - (optional) DateTime the order was fulfilled
      #                      defaults to the current time
      def content_for_ship_with(opts={})
        fulfillment_date = opts[:fulfillment_date] || DateTime.now
        tracking_el = opts[:tracking_number] ? "<ShipperTrackingNumber>#{opts[:tracking_number]}</ShipperTrackingNumber>" : ""
        items = opts[:items].map do |item_hash|
          content_for_item(item_hash)
        end.join("\n")
        
        body = <<-BODY
<?xml version="1.0" encoding="UTF-8"?>
<AmazonEnvelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="amznenvelope.xsd">
<Header>
<DocumentVersion>1.01</DocumentVersion>
<MerchantIdentifier>#{@connection.seller_id}</MerchantIdentifier>
</Header>
<MessageType>OrderFulfillment</MessageType>
<Message>
<MessageID>1</MessageID>
<OrderFulfillment>
<MerchantOrderID>#{opts[:merchant_order_id]}</MerchantOrderID>
<MerchantFulfillmentID>#{opts[:merchant_order_id]}</MerchantFulfillmentID>
<FulfillmentDate>#{fulfillment_date}</FulfillmentDate>
<FulfillmentData>
<CarrierCode>#{opts[:carrier_code]}</CarrierCode>
<ShippingMethod>#{opts[:shipping_method]}</ShippingMethod>
#{tracking_el}
</FulfillmentData>
#{items}
</OrderFulfillment>
</Message>
</AmazonEnvelope>
BODY
      end

      def content_for_item(opts={})
        str = '<Item>'
        str += "<AmazonOrderItemCode>#{opts[:amazon_order_item_code]}</AmazonOrderItemCode>"
        str += "<Quantity>#{opts[:quantity]}</Quantity>" if opts[:quantity]
        
        str
      end
    end
  end
end
