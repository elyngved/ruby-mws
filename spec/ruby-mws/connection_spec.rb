require 'spec_helper'

describe MWS::Connection do

  context "initialize" do
    it "should intialize with all requires params" do
      conn = MWS::Connection.new default_params
      conn.class.should == MWS::Connection
      default_params.each do |k,v|
        conn.send(k).should == v
      end
      conn.host.should == "mws.amazonservices.com"
    end

    it "should raise an exception when a required param is missing" do
      default_params.each do |k,v|
        lambda { MWS::Connection.new default_params.delete(k) }.should raise_error
      end
    end

    it "should override host when sent a host param" do
      conn = MWS::Connection.new default_params.merge({host: 'newhost.com'})
      conn.host.should == 'newhost.com'
    end
  end


  def default_params
    {
      aws_access_key_id: 'access_key',
      seller_id:         'seller',
      marketplace:       'market',
      secret_access_key: 'secret123'
    }
  end
end