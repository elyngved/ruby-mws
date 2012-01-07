require "ruby-mws/version"
require "httparty"

module MWS
  def self.connect(options={})
    MWS::Base.new(options)
  end
end

require 'ruby-mws/base'
require 'ruby-mws/connection'
require 'ruby-mws/exceptions'