require 'digest/md5'
require 'tempfile'
require 'iconv'

module MWS
  module API
    class Feed < Base
      def submit_feed(query_params={})
        query_params = {:feed_type => '_POST_ORDER_ACKNOWLEDGEMENT_DATA_'}
        options = {
          :verb => :post,
          :uri => '/',
          :version => '2009-01-01'
        }
        params = [default_params('submit_feed'), query_params, options, @connection.to_hash].inject :merge
        query = Query.new params
        body = Iconv.conv("iso-8859-1", "UTF8", example_body)
        resp = self.class.post(query.request_uri, :body => body,
                               :headers => {'Content-MD5' => Digest::MD5.file(body).hexdigest})

        resp
      end

      def example_body
        body = <<-BODY
<?xml version="1.0"?> 
<AmazonEnvelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="amzn-envelope.xsd"> 
<Header> 
<DocumentVersion>1.01</DocumentVersion> 
<MerchantIdentifier>A3IGWI0VX4DJJM</MerchantIdentifier> 
</Header> 
<MessageType>OrderAcknowledgment</MessageType> 
<Message> 
<MessageID>1</MessageID> 
<OrderAcknowledgement> 
<AmazonOrderID>050-1234567-1234567</AmazonOrderID> 
<MerchantOrderID>1234567</MerchantOrderID> 
<StatusCode>Success</StatusCode> 
<Item> 
<AmazonOrderItemCode>12345678901234</AmazonOrderItemCode> 
<MerchantOrderItemID>1234567</MerchantOrderItemID> 
</Item> 
</OrderAcknowledgment> 
</Message> 
</AmazonEnvelope>
BODY
      end
    end
  end
end
