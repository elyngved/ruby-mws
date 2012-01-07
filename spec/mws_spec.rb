require 'spec_helper'

describe MWS do
  context '.ping' do
    it "should respond to me!" do
      MWS.ping.should == "MWS here!"
    end

    it "should connect and get a timestamp" do
      MWS.get_server_time.class.should == Time
    end
  end
end