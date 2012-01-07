require 'spec_helper'

describe MWS::Base do

  it "should connect and get a timestamp" do
    MWS::Base.get_server_time.class.should == Time
  end

  context 'connect' do
    it "should create a connection object" do
      mws = MWS.connect(options)
      mws.should be
      mws.connection.should be
      mws.connection.access_key.should == 'access'
    end
  end

  def options
    {
      :access_key => 'access',
      :secret_access_key => 'super_secret',
      :merchant_id => 'doma',
      :marketplace_id => '123'
    }
  end

end