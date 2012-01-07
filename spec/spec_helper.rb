require 'rubygems'
require 'bundler/setup'
require 'awesome_print'

require 'ruby-mws' # and any other gems you need

RSpec.configure do |config|
  # some (optional) config here
  def options
    {
      :access_key => 'access',
      :secret_access_key => 'super_secret',
      :merchant_id => 'doma',
      :marketplace_id => '123'
    }
  end
end