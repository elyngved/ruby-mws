require 'httparty'
require 'base64'
require 'cgi'
require 'openssl'
require 'hmac-sha1'

module MWS
  def self.connect(options={})
    MWS::Base.new(HashWithIndifferentAccess.new(options))
  end
end

require 'ruby-mws/base'
require 'ruby-mws/connection'
require 'ruby-mws/exceptions'
require 'ruby-mws/version'

require 'ruby-mws/api/base'
require 'ruby-mws/api/order'
require 'ruby-mws/api/query'