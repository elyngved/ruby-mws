module MWS

  class Connection

    DEFAULT_HOST = "mws.amazonservices.com"

    def initialize(options={})
      attrs.each do |a|
        self.class.send(:attr_reader, a)
        instance_variable_set("@#{a}", options[a])
      end

      @host ||= DEFAULT_HOST

      attrs.each { |a| raise MissingConnectionOptions, ":#{a} is required" if instance_variable_get("@#{a}").nil?}

      @response_callback = options[:response_callback]
      @request_callback = options[:request_callback]
    end

    def public_attrs
      [:aws_access_key_id, :seller_id, :marketplace_id, :host]
    end

    def private_attrs
      [:secret_access_key]
    end

    def attrs
      public_attrs + private_attrs
    end

    # an attempt to hide sensitive login credentials in logs, just being paranoid
    def inspect
      "#<MWS::Connection:#{object_id}>"
    end

    def server_time
      self.class.server_time @host
    end

    def to_hash
      hsh = {}
      attrs.each { |a| hsh[a] = instance_variable_get("@#{a}")}
      hsh
    end

    # No connection needs to be initialized for this call
    def self.server_time(host=DEFAULT_HOST)
      response = HTTParty.get("https://#{host}")
      Time.parse(response['PingResponse']['Timestamp']['timestamp'])
    end

    # Calls the request_callback and response_callback (in that order)
    # if they're defined
    #
    # @param comm [Hash] the communications between amazon and us
    # @option comm [Hash]   :params the request parameters
    # @option comm [String] :body the request body
    # @option comm [Hash]   :response [HTTParty::Response] The response returned
    #   by HTTParty
    def call_communication_callbacks(comm)
      @request_callback.call(comm[:params], comm[:body] || '') if @request_callback
      @response_callback.call(comm[:response]) if @response_callback
    end
  end

end
