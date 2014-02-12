require 'digest/md5'

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
        body = ''
        resp = self.class.post(query.request_uri, :body => body, :headers => {'Content-MD5' => Digest::MD5.hexdigest(body)})
      end
    end
  end
end
