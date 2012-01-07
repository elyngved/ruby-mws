require 'rubygems'
require 'bundler/setup'
require 'awesome_print'

require 'ruby-mws'

RSpec.configure do |config|
  def options
    {
      :access_key => 'access',
      :secret_access_key => 'super_secret',
      :merchant_id => 'doma',
      :marketplace_id => '123'
    }
  end
end