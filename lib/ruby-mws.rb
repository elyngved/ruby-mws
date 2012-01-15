require 'rubygems'
require 'httparty'
require 'base64'
require 'cgi'
require 'openssl'
# require 'hashie/mash'
require 'hashie'
require 'rash'

module MWS
  def self.new(options={})
    MWS::Base.new(options.symbolize_keys!)
  end
end

# Some convenience methods randomly put here. Thanks, Rails

class Hash
  def stringify_keys!
    keys.each do |key|
      self[key.to_s] = delete(key)
    end
    self
  end

  def symbolize_keys!
    self.replace(self.symbolize_keys)
  end

  def symbolize_keys
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end
end

class String

  def camelize(first_letter_in_uppercase = true)
    if first_letter_in_uppercase
      self.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    else
      self.to_s[0].chr.downcase + camelize(lower_case_and_underscored_word)[1..-1]
    end
  end
end

require 'ruby-mws/base'
require 'ruby-mws/connection'
require 'ruby-mws/exceptions'
require 'ruby-mws/version'

require 'ruby-mws/api/base'
require 'ruby-mws/api/inventory'
require 'ruby-mws/api/order'
require 'ruby-mws/api/query'
require 'ruby-mws/api/response'