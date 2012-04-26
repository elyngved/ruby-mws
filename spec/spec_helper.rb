require 'rubygems'
require 'bundler/setup'
require 'awesome_print'
require 'ephemeral_response'

require 'ruby-mws'

RSpec.configure do |config|
  def fixture(path)
    File.open(File.join(File.expand_path(File.dirname(__FILE__)), 'fixtures', path)).read
  end

  def mws_object
    @mws_object ||= MWS.new(auth_params)
  end

  # To test, create spec/credentials.yml or fill in below
  def auth_params
    @auth_params ||=
      begin
        hsh = YAML.load(File.open(File.join(File.expand_path(File.dirname(__FILE__)), 'credentials.yml'))).symbolize_keys!
      rescue
        {
          :aws_access_key_id  => 'access',
          :secret_access_key  => 'super_secret',
          :seller_id          => 'doma',
          :marketplace_id     => '123'
        }
      end
  end
end

class TestWorksError < StandardError
end