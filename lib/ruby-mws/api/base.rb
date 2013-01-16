# This class serves as a parent class to the API classes.
# It shares connection handling, query string building, ?? among the models.

require 'digest'
require 'base64'

module MWS
  module API

    class Base
      include HTTParty
      # debug_output $stderr  # only in development
      format :xml
      headers "User-Agent"   => "ruby-mws/#{MWS::VERSION} (Language=Ruby/1.9.3-p0)"
      headers "Content-Type" => "text/xml"

      attr_accessor :response

      def initialize(connection)
        @connection = connection
        @saved_options = {}
        @next = {}
        self.class.base_uri "https://#{connection.host}"
      end

      def self.def_request(requests, *options)
        [requests].flatten.each do |name|
          self.class_eval %Q{
            @@#{name}_options = options.first
            def #{name}(params={})
              send_request(:#{name}, params, @@#{name}_options)
            end
          }
        end
      end

      def send_request(name, params, options={})
        # prepare all required params...
        params = [params, options, @connection.to_hash].inject :merge
        
        # default/common params
        params[:action]            ||= name.to_s.camelize
        params[:verb]              ||= :get
        params[:signature_method]  ||= 'HmacSHA256'
        params[:signature_version] ||= '2'
        params[:timestamp]         ||= Time.now.iso8601
        params[:version]           ||= '2009-01-01'
        params[:uri]               ||= '/'

        params[:lists] ||= {}
        params[:lists][:marketplace_id] = "MarketplaceId.Id"

        query = Query.new params
        resp  = self.class.send(params[:verb], query.request_uri, query.http_options)

        content_type = resp.headers['content-type']
        if not content_type =~ /text\/xml/ || content_type =~ /application\/xml/
          raise "Expected to receive XML response from Amazon MWS! Actually received: #{content_type}\nStatus: #{resp.response.code}\nBody: #{resp.body.size > 4000 ? resp.body[0...4000] + '...' : resp.body}"
        end

        @response = Response.parse resp, name, params
        if @response.respond_to?(:next_token) and @next[:token] = @response.next_token  # modifying, not comparing
          @next[:action] = name.match(/_by_next_token/) ? name : "#{name}_by_next_token"
        end
        @response
      end

      def has_next?
        not @next[:token].nil?
      end
      alias :has_next :has_next?

      def next
        self.send(@next[:action], :next_token => @next[:token]) unless @next[:token].nil?
      end

      def inspect
        "#<#{self.class.to_s}:#{object_id}>"
      end

    end

  end
end