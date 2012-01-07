require "ruby-mws/version"
require "httparty"

module MWS
  def self.ping
    "MWS here!"
  end

  def self.get_server_time
  	response = HTTParty.get("https://mws.amazonservices.com/")
  	Time.parse(response['PingResponse']['Timestamp']['timestamp'])
  end
end