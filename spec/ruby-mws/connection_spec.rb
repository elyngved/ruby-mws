require 'spec_helper'

describe MWS::Connection do

  context "initialize" do
    it "should intialize with all requires params" do
      conn = MWS::Connection.new auth_params
      conn.class.should == MWS::Connection
      auth_params.each do |k,v|
        conn.send(k).should == v
      end
      conn.host.should == "mws.amazonservices.com"
    end

    it "should raise an exception when a required param is missing" do
      auth_params.each do |k,v|
        lambda { MWS::Connection.new auth_params.delete(k) }.should raise_error
      end
    end

    it "should override host when sent a host param" do
      conn = MWS::Connection.new auth_params.merge({host: 'newhost.com'})
      conn.host.should == 'newhost.com'
    end
  end
end