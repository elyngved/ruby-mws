module MWS
  module API
    class Feed < Base
      def submit_feed
        options = {
          :verb => :post,
          :uri => '/',
          :version => '2009-01-01'
        }
        params = [default_params('submit_feed'), options, @connection.to_hash].inject :merge
        query = Query.new params
        resp = self.class.post(query.request_uri)
      end
    end
  end
end
