require 'digest/md5'
require 'nokogiri'

module MWS
  module API
    class Feed < Base
      ORDER_ACK = '_POST_ORDER_ACKNOWLEDGEMENT_DATA_'
      SHIP_ACK = '_POST_ORDER_FULFILLMENT_DATA_'

      # POSTs a request to the submit feed action of the feeds api
      #
      # @param type [String] either MWS::API::Feed::ORDER_ACK or SHIP_ACK
      # @param content_params [Hash{Symbol => String,Hash,Integer}]
      # @return [MWS::API::Response] The response from Amazon
      # @todo Think about whether we should make this more general
      #   for submission back to the author's fork
      def submit_feed(type=nil, content_params={})
        name = :submit_feed
        body = case type
               when ORDER_ACK
                 content_for_ack_with(content_params)
               when SHIP_ACK
                 content_for_ship_with(content_params)
               end
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
      # Returns a string containing the order acknowledgement xml
      #
      # @param opts [Hash{Symbol => String}] contains
      # @option opts [String] :amazon_order_item_code ID of the specific item in the order
      # @option opts [String] :amazon_order_id ID of the order on amazon's side
      # @option opts [String] :merchant_order_id Internal order id
      def content_for_ack_with(opts={})
        Nokogiri::XML::Builder.new do |xml|
          xml.root {
            xml.AmazonEnvelope("xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                               "xsi:noNamespaceSchemaLocation" => "amzn-envelope.xsd") { # add attrs here
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
      # @param [Hash{Symbol => String,Array,DateTime}] opts contains:
      # @option opts [String] :merchant_order_id The internal order id
      # @option opts [String] :carrier_code Represents a shipper code
      #   possible codes are USPS, UPS, FedEx, DHL, Fastway, GLS, GO!,
      #   NipponExpress, YamatoTransport, Hermes Logistik Gruppe,
      #   Royal Mail, Parcelforce, City Link, TNT, Target, SagawaExpress
      # @option opts [String] :shipping_method string describing method (i.e. 2nd Day)
      # @option opts [Array<Hash>] :items item specifics including :amazon_order_item_code
      #   and :quantity keys
      # @option opts [String] :tracking_number (optional) shipper tracking number
      # @option opts [String] :fulfillment_date (optional) DateTime the order was fulfilled
      #   defaults to the current time
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
