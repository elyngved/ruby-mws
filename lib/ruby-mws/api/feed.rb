require 'digest/md5'
require 'tempfile'
require 'iconv'

module MWS
  module API
    class Feed < Base
      ORDER_ACK = '_POST_ORDER_ACKNOWLEDGEMENT_DATA_'
      
      # TODO: think about whether we should make this more general
      # for submission back to the author's fork
      def submit_feed(type=nil, content_params={})
        name = :submit_feed
        body = case type
               when ORDER_ACK
                 content_for_ack_with(content_params)
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
    end
  end
end
