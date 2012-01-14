require 'spec_helper'

describe MWS do

  context 'connect' do
    it 'should create a MWS::Base object' do
      MWS.connect(auth_params).class.should == MWS::Base
    end
  end

end