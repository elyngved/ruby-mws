require 'digest/md5'
require 'iconv'
require 'nokogiri'

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
      # opts require amazon_order_item_code, amazon_order_id, and merchant_order_id (internal order id)
      def content_for_ack_with(opts={})
        Nokogiri::XML::Builder.new do |xml|
          xml.root {
            xml.AmazonEnvelope(:"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                               :"xsi:noNamespaceSchemaLocation" => "amzn-envelope.xsd") { # add attrs here
              xml.Header {
                xml.DocumentVersion "1.01"
                xml.MerchantIdentifier @connection.seller_id
              }
              xml.MessageType "OrderAcknowledgement"
              xml.Message {
                xml.MessageID "1"
                xml.OrderAchnowledgement {
                  xml.AmazonOrderID opts[:amazon_order_id]
                  xml.StatusCode "Success"
                  xml.Item {
                    xml.AmazonOrderItemCode opts[:amazon_order_item_code]
                  }
                }
              }
            }
          }
        end.to_xml
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

        Nokogiri::XML::Builder.new do |xml|
          xml.AmazonEnvelope('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                             'xsi:noNamespaceSchemaLocation' => 'amznenvelope.xsd') {
            xml.Header {
              xml.DocumentVersion "1.01"
              xml.MerchantIdentifier @connection.seller_id
            }
            xml.MessageType "OrderFulfillment"
            xml.Message {
              xml.MessageID "1"
              xml.OrderFulfillment {
                xml.MerghantOrderID opts[:merchant_order_id]
                xml.MerchantFulfillmentID opts[:merchant_order_id]
                xml.FulfillmentDate fulfillment_date
                xml.FulfillmentData {
                  xml.CarrierCode opts[:carrier_code]
                  xml.ShippingMethod opts[:shipping_method]
                  xml.ShipperTrackingNumber opts[:tracking_number] if opts[:tracking_number]
                  opts[:items].each do |item_hash|
                    xml.Item {
                      xml.AmazonOrderItemCode opts[:amazon_order_item_code]
                      xml.Quantity opts[:quantity]
                    }
                  end
                }
              }
            }
          }
        end.to_xml
      end
    end
  end
end
