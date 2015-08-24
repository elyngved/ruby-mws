require 'digest/md5'
require 'nokogiri'

module MWS
  module API
    class Feed < Base
      ORDER_ACK = '_POST_ORDER_ACKNOWLEDGEMENT_DATA_'
      SHIP_ACK = '_POST_ORDER_FULFILLMENT_DATA_'
      PRODUCT_LIST = '_POST_PRODUCT_DATA_'
      PRODUCT_LIST_IMAGE = '_POST_PRODUCT_IMAGE_DATA_'
      PRODUCT_LIST_PRICE = '_POST_PRODUCT_PRICING_DATA_'
      PRODUCT_LIST_INVENTORY = '_POST_INVENTORY_AVAILABILITY_DATA_'
      PRODUCT_FLAT_FILE_INVLOADER = '_POST_FLAT_FILE_INVLOADER_DATA_'

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
               when PRODUCT_LIST
                 content_for_product_list(content_params)
               when PRODUCT_LIST_IMAGE
                 content_for_product_list_image(content_params)
               when PRODUCT_LIST_PRICE
                 content_for_product_list_price(content_params)
               when PRODUCT_LIST_INVENTORY
                 content_for_product_list_inventory(content_params)
               when PRODUCT_FLAT_FILE_INVLOADER
                 content_for_product_flat_file_invloader(content_params)
               end
        query_params = {:feed_type => type}
        submit_to_mws(name, body, query_params)
      end

      def feed_submission_result(feed_submission_id)
        name = :get_feed_submission_result
        body = ""
        query_params = {:feed_submission_id => feed_submission_id}
        submit_to_mws(name, body, query_params)
      end


      private

      def submit_to_mws(name, body, query_params)
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
        @connection.call_communication_callbacks(:params => query.safe_params,
                                                 :body => body,
                                                 :response => resp)
        Response.parse resp, name, params
      end

      def amazon_envelope_with_header
        Nokogiri::XML::Builder.new do |xml|
          xml.AmazonEnvelope("xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xsi:noNamespaceSchemaLocation" => "amzn-envelope.xsd") { # add attrs here
            xml.Header {
              xml.DocumentVersion "1.01"
              xml.MerchantIdentifier @connection.seller_id
            }
            yield xml
          }
        end
      end

      def content_for_product_list_price(opts={})
        amazon_envelope_with_header do |xml|
          xml.MessageType "Price"
          xml.PurgeAndReplace opts[:purge_and_replace]
          opts[:entries].each do |entry|
            xml.Message {
              xml.MessageID entry[:message_id]
              xml.OperationType entry[:operation_type]
              xml.Price {
                xml.SKU entry[:isbn]
                xml.StandardPrice(:currency => entry[:currency]){ xml.text(entry[:standard_price]) }
              }
            }
          end
        end.to_xml
      end

      def content_for_product_list_inventory(opts={})
        amazon_envelope_with_header do |xml|
          xml.MessageType "Inventory"
          xml.PurgeAndReplace opts[:purge_and_replace]
          opts[:entries].each do |entry|
            xml.Message {
              xml.MessageID entry[:message_id]
              xml.OperationType entry[:operation_type]
              xml.Inventory {
                xml.SKU entry[:isbn]
                xml.Quantity entry[:quantity]
              }
            }
          end
        end.to_xml
      end

      def content_for_product_list_image(opts={})
        amazon_envelope_with_header do |xml|
          xml.MessageType "ProductImage"
          xml.PurgeAndReplace opts[:purge_and_replace]
          opts[:entries].each do |entry|
            xml.Message {
              xml.MessageID entry[:message_id]
              xml.OperationType entry[:operation_type]
              xml.ProductImage {
                xml.SKU entry[:isbn]
                xml.ImageType entry[:image_type]
                xml.ImageLocation entry[:image_location]
              }
            }
          end
        end.to_xml
      end

      def content_for_product_flat_file_invloader(opts={})
        CSV.generate({:col_sep=>"\t"}) do |csv|
          csv << ['TemplateType=InventoryLoader', 'Version=2014.0415']
          csv << ['SKU', 'Will Ship Internationally']
          csv << ['item_sku', 'will_ship_internationally']
          opts[:entries].each do |entry|
              csv << [entry[:isbn], 'y']
          end
        end
      end

      # Returns a string containing the order acknowledgement xml
      #
      # @param opts [Hash{Symbol => String}] contains
      # @option opts [String] :amazon_order_item_code ID of the specific item in the order
      # @option opts [String] :amazon_order_id ID of the order on amazon's side
      # @option opts [String] :merchant_order_id Internal order id
      # @option opts [String] :merchant_order_item_id Internal order line item id
      def content_for_product_list(opts={})
        amazon_envelope_with_header do |xml|
          xml.MessageType "Product"
          xml.PurgeAndReplace opts[:purge_and_replace]
          opts[:entries].each do |entry_hash|
            xml.Message {
              xml.MessageID entry_hash[:message_id]
              xml.OperationType entry_hash[:operation_type]
              xml.Product {
                xml.SKU entry_hash[:isbn]
                xml.StandardProductID {
                  xml.Type  "ISBN"
                  xml.Value entry_hash[:isbn]
                }
                if entry_hash[:operation_type] != "Delete"
                  get_addition_data(xml, entry_hash)
                end
              }
            }
          end
        end.to_xml
      end

      def get_addition_data(xml, entry_hash)
        xml.Condition {
          xml.ConditionType entry_hash[:item_condition_type]
        }
        xml.ItemPackageQuantity entry_hash[:item_package_quantity]
        xml.NumberOfItems entry_hash[:number_of_items]
        xml.DescriptionData {
          xml.Title entry_hash[:title]
          xml.Brand entry_hash[:brand]
          xml.Description entry_hash[:description]
          xml.PackageDimensions {
            xml.Length(:unitOfMeasure => entry_hash[:unit_of_measure]) { xml.text(entry_hash[:package_length]) }
            xml.Width(:unitOfMeasure => entry_hash[:unit_of_measure]) { xml.text(entry_hash[:package_width]) }
            xml.Height(:unitOfMeasure => entry_hash[:unit_of_measure]) { xml.text(entry_hash[:package_height]) }
          }
          xml.MSRP(:currency => entry_hash[:currency]){ xml.text(entry_hash[:standard_price]) }
          xml.Manufacturer entry_hash[:manufacturer]
            entry_hash[:search_terms][:taggings].each do |search_term|
              xml.SearchTerms {xml.text(search_term[:tag_name])}
            end if !entry_hash[:search_terms].nil?
        }
        xml.ProductData {
          xml.Books {
            xml.ProductType {
              xml.BooksMisc {
                xml.Author entry_hash[:authors]
                xml.Binding entry_hash[:binding]
                xml.PublicationDate entry_hash[:publication_date]
              }
            }
          }
        }
      end


      # @option opts [String] :status_code (optional) Ack status code. Defaults to 'Success'
      # @option opts [String] :merchant_order_item_id (optional) Internal order line item id
      # @option opts [Array<Hash{Symbol=>String}>] :items (optional) list of items in the order
      def content_for_ack_with(opts={})
        amazon_envelope_with_header do |xml|
          xml.MessageType "OrderAcknowledgement"
          xml.Message {
            xml.MessageID "1"
            xml.OrderAcknowledgement {
              xml.AmazonOrderID opts[:amazon_order_id]
              xml.MerchantOrderID opts[:merchant_order_id]
              xml.StatusCode opts[:status_code] || "Success"
              (opts[:items] || [opts]).each do |item_hash|
                xml.Item {
                  xml.AmazonOrderItemCode item_hash[:amazon_order_item_code]
                  xml.MerchantOrderItemID item_hash[:merchant_order_item_id]
                }
              end
            }
          }
        end.to_xml
      end

      # Returns a string containing the shipping achnowledgement xml
      #
      # @param [Hash{Symbol => String,Array,DateTime}] opts contains:
      # @option opts [Array<Hash>] :orders order specifics including:
      #   @option opts [String] :merchant_order_id The internal order id
      #   @option opts [String] :amazon_order_id The id assigned to the order
      #     by amazon.
      #   @option opts [String] :carrier_code Represents a shipper code
      #     possible codes are USPS, UPS, FedEx, DHL, Fastway, GLS, GO!,
      #     NipponExpress, YamatoTransport, Hermes Logistik Gruppe,
      #     Royal Mail, Parcelforce, City Link, TNT, Target, SagawaExpress
      #   @option opts [String] :shipping_method string describing method (i.e. 2nd Day)
      #   @option opts [Array<Hash>] :items item specifics including:
      #     :amazon_order_item_code
      #     :quantity keys
      #   @option opts [String] :tracking_number (optional) shipper tracking number
      #   @option opts [String] :fulfillment_date (optional) DateTime the order was fulfilled
      #     defaults to the current time
      #   @option opts [String] :merchant_order_item_id Internal order line item id
      def content_for_ship_with(opts={})
        fulfillment_date = opts[:fulfillment_date] || DateTime.now

        amazon_envelope_with_header do |xml|
          xml.MessageType "OrderFulfillment"
          opts[:orders].each do |order_hash|
            xml.Message {
              xml.MessageID order_hash[:message_id]
              xml.OrderFulfillment {
                xml.AmazonOrderID order_hash[:amazon_order_id]
                xml.FulfillmentDate fulfillment_date
                xml.FulfillmentData {
                  xml.CarrierCode order_hash[:carrier_code]
                  xml.ShippingMethod order_hash[:shipping_method]
                  xml.ShipperTrackingNumber order_hash[:tracking_number] if order_hash[:tracking_number]
                }
                order_hash[:items].each do |item_hash|
                  xml.Item {
                    xml.AmazonOrderItemCode item_hash[:amazon_order_item_code]
                    xml.Quantity item_hash[:quantity]
                  }
                end
              }
            }
          end
        end.to_xml
      end
    end
  end
end
