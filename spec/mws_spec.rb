require 'spec_helper'

describe MWS do
  context '.ping' do
    it "should respond to me!" do
      MWS.ping.should == "MWS here!"
    end
  end
end