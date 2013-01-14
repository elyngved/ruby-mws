require 'builder'

module MWS
  module API

    class Inventory < Base

      def_request [:list_inventory_supply, :list_inventory_supply_by_next_token],
        :verb => :post,
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

        response = send_request(:submit_feed, :feed_type => '_POST_INVENTORY_AVAILABILITY_DATA_', :body => xml, :verb => :post, :content_md5 => true)

        # Amazon returns FeedSubmissionId, which we use to check if submission was successful
        submission_id = response.feed_submission_info.feed_submission_id

        # first wait until Amazon is finished processing the feed
        # this usually takes at least something close to a minute
        # so don't check back too frequently -- otherwise our FeedSubmissionList
        #   queries will be throttled
        while true
          sleep(20)
          response = send_request(:get_feed_submission_list, :lists => {:feed_submission_ids => "FeedSubmissionIdList.Id"}, :feed_submission_ids => [submission_id])
          break if response.feed_submission_info.feed_processing_status == '_DONE_'
        end

        # then check whether there were any errors
        response = send_request(:get_feed_submission_result, :feed_submission_id => submission_id)

        errors = ""
        [*response.message.processing_report.result].each do |result|
          if %w{Warning Error}.include? result.result_code
            errors << result.result_description
            if result.additional_info && !result.additional_info.empty?
              errors << " (additional info: "
              errors << result.additional_info.map { |k,v| "#{k}=#{v}" }.join(' ')
              errors << ")"
            end
            errors << "\n"
          end
        end

        errors.empty? || (raise ErrorResponse, errors)
      end
    end

  end
end