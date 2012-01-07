module MWS

  class Base
    include HTTParty
    base_uri "https://mws.amazonservices.com"

    attr_accessor :connection

    def initialize(options={})
      @connection = MWS::Connection.new(options)
    end

    def self.get_server_time
      response = get("/")
      Time.parse(response['PingResponse']['Timestamp']['timestamp'])
    end
  end
end