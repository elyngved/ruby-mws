require 'spec_helper'

describe MWS::Base do

  it "should connect and get a timestamp" do
    MWS::Base.server_time.class.should == Time
  end

  context 'initialize' do
    it "should create a connection object" do
      mws = MWS::Base.new(auth_params)
      mws.should be
      mws.connection.should be
      mws.connection.class.should == MWS::Connection
    end
  end

end