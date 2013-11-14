require 'builder'

module MWS
  module API

    class Inventory < Base
      include Feeds

      def_request [:list_inventory_supply, :list_inventory_supply_by_next_token],
        :verb => :get,
        :uri => '/FulfillmentInventory/2010-10-01',
        :version => '2010-10-01',
        :lists => {
          :seller_skus => "SellerSkus.member"
        },
        :mods => [
          lambda {|r| r.inventory_supply_list = [r.inventory_supply_list.member].flatten}
        ]

      # Takes a hash of SKUs -> quantities
      # Returns true if all the products were updated successfully
      # Otherwise raises an exception
      def update_inventory_supply(merchant_id, hash)
        # updating inventory is done by sending an XML "feed" to Amazon
        # as of this writing, XML schema docs are available at:
        # https://images-na.ssl-images-amazon.com/images/G/01/rainier/help/XML_Documentation_Intl.pdf
        xml     = ""
        builder = Builder::XmlMarkup.new(:indent => 2, :target => xml)
        builder.instruct! # <?xml version="1.0" encoding="UTF-8"?>
        builder.AmazonEnvelope(:"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :"xsi:noNamespaceSchemaLocation" => "amzn-envelope.xsd") do |env|
          env.Header do |head|
            head.DocumentVersion('1.01')
            head.MerchantIdentifier(merchant_id)
          end
          env.MessageType('Inventory')
          i = 0
          hash.each do |sku,quantity|
            env.Message do |msg|
              msg.MessageID(i += 1)
              msg.OperationType('Update')
              msg.Inventory do |inv|
                inv.SKU(sku)
                inv.Quantity(quantity)
              end
            end
          end
        end

        submit_feed('_POST_INVENTORY_AVAILABILITY_DATA_', xml)
      end

      # Takes a currency code and a hash of SKUs -> prices
      # Returns true if all the products were updated successfully
      # Otherwise raises an exception
      def update_inventory_prices(merchant_id, currency_code, hash)
        # schema for XML "feed" is available at:
        # https://images-na.ssl-images-amazon.com/images/G/01/rainier/help/XML_Documentation_Intl.pdf
        xml = ""
        builder = Builder::XmlMarkup.new(:indent => 2, :target => xml)
        builder.instruct!
        builder.AmazonEnvelope(:"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :"xsi:noNamespaceSchemaLocation" => "amzn-envelope.xsd") do |env|
          env.Header do |head|
            head.DocumentVersion('1.01')
            head.MerchantIdentifier(merchant_id)
          end
          env.MessageType('Price')
          i = 0
          hash.each do |sku,price|
            env.Message do |msg|
              msg.MessageID(i += 1)
              msg.Price do |pr|
                pr.SKU(sku)
                pr.StandardPrice(price, 'currency' => currency_code)
              end
            end
          end
        end

        submit_feed('_POST_PRODUCT_PRICING_DATA_', xml)
      end
    end

  end
end
