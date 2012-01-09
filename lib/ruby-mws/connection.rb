module MWS

  class Connection

    DEFAULT_HOST = "mws.amazonservices.com"
    # attr_reader :host

    def initialize(options={})
      attrs.each do |a|
        self.class.send(:attr_reader, a)
        instance_variable_set("@#{a}", options[a])
      end

      @host ||= DEFAULT_HOST

      attrs.each { |a| raise MissingConnectionOptions, ":#{a} is required" if instance_variable_get("@#{a}").nil?}
    end

    def public_attrs
      [:aws_access_key_id, :seller_id, :marketplace, :host]
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
  end

end