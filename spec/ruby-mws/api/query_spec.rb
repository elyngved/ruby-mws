require 'spec_helper'

describe MWS::API::Query do 
  before do
    @query = MWS::API::Query.new(default_params)
    @query.stub!(:signature).and_return("SIGNATURE")
  end

  context ".query" do
    it "should assemble the canonical query" do
      @query.canonical.should == %Q{GET
mws.amazonservices.com
/Orders/2011-01-01
AWSAccessKeyId=#{default_params[:aws_access_key_id]}&Action=ListOrders&LastUpdatedAfter=2012-01-13T15%3A48%3A55-05%3A00&MarketplaceId.Id.1=#{default_params[:marketplace_id]}&SellerId=#{default_params[:seller_id]}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=2012-01-14T15%3A48%3A55-05%3A00&Version=2011-01-01}
    end
  end

  context ".request_uri" do
    it "should assemble the request uri" do
      @query.request_uri.should == "https://mws.amazonservices.com/Orders/2011-01-01?AWSAccessKeyId=#{default_params[:aws_access_key_id]}&Action=ListOrders&LastUpdatedAfter=2012-01-13T15%3A48%3A55-05%3A00&MarketplaceId.Id.1=#{default_params[:marketplace_id]}&SellerId=#{default_params[:seller_id]}&Signature=SIGNATURE&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=2012-01-14T15%3A48%3A55-05%3A00&Version=2011-01-01"
    end
  end

  def default_params
    # some random keys
    params = {
      :last_updated_after => "2012-01-13T15:48:55-05:00",
      :verb               => :get,
      :uri                => "/Orders/2011-01-01",
      :version            => "2011-01-01",
      :host               => "mws.amazonservices.com",
      :action             => "ListOrders",
      :signature_method   => "HmacSHA256",
      :signature_version  => "2",
      :timestamp          => "2012-01-14T15:48:55-05:00",
      :lists              => {
        :marketplace_id   => "MarketplaceId.Id"
      }
    }.merge(auth_params)
  end

end
  