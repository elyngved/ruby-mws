# This class serves as a parent class to the API classes.
# It shares connection handling, query string building, ?? among the models.

module MWS
  module API

    class Base
      include HTTParty
      parser MWS::API::BinaryParser
      debug_output $stderr  # only in development
      #format :xml
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
        params = [default_params(name), params, options, @connection.to_hash].inject :merge

        params[:lists] ||= {}
        params[:lists][:marketplace_id] ||= "MarketplaceId.Id"

        query = Query.new params
        resp = self.class.send(params[:verb], query.request_uri)

        @response = Response.parse resp, name, params

        if @response.respond_to?(:next_token) and @next[:token] = @response.next_token  # modifying, not comparing
          @next[:action] = name.match(/_by_next_token/) ? name : "#{name}_by_next_token"
        end
        @response
      end

      def default_params(name)
        {
          :action            => name.to_s.camelize,
          :signature_method  => 'HmacSHA256',
          :signature_version => '2',
          :timestamp         => Time.now.iso8601,
          :version           => '2009-01-01'
        }
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
