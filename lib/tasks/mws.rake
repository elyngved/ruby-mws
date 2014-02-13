require 'pp'

desc "This task is called by the Heroku scheduler add-on"

namespace :mws do
  desc "Test download from BetterMWS"
  task :'test-better' => :environment do
    asin = 'B002DYJTVW'
    url = 'http://api.bettermws.com/v1/lookup?'
    params = {
      merchant_id: ENV['MERCHANT_ID'],
      marketplace_id: ENV['MARKETPLACE_ID'],
      asin: asin,
      persist: 24,
      format: 'json',
      ts: Time.now.to_i
    }

    url += params.to_query
    
    url += "&sig=" + Digest::MD5.hexdigest(ENV['AWS_KEY'] + url)
    
    uri = URI.parse(url)
    req = Net::HTTP::Get.new(uri.to_s)
    res = Net::HTTP.start(uri.host, uri.port) { |http| http.request(req) }
    puts url
    puts res.body
  end

  desc "Print server time"
  task time: :environment do
    puts MWS::Base.server_time
  end

  desc "List orders"
  task orders: :environment do
    response = mws.orders.list_orders last_updated_after: 4.hours.ago

    pp response.orders
  end

  # rake mws:product[B002DYJTVW,B0018KVHJO]
  desc "List product"
  task :product, [*1..10].map!{ |i| ("ASINList.ASIN." + i.to_s).to_sym }  =>  :environment do |t, args|
    args.with_defaults(:'ASINList.ASIN.1' => 'B002DYJTVW', :'ASINList.ASIN.2' => 'B0018KVHJO') if not args[:'ASINList.ASIN.1']

    # should be response.products
    products = mws.products.get_matching_product args

    pp products
  end

  desc "Competitive pricing"
  task :cprice, [*1..10].map!{ |i| ("ASINList.ASIN." + i.to_s).to_sym }  =>  :environment do |t, args|
    args.with_defaults(:'ASINList.ASIN.1' => 'B002DYJTVW', :'ASINList.ASIN.2' => 'B0018KVHJO') if not args[:'ASINList.ASIN.1']

    response = mws.products.get_competitive_pricing_for_ASIN args

    pp response
  end

  desc "Lowest price listing"
  task :lprice, [*1..10].map!{ |i| ("ASINList.ASIN." + i.to_s).to_sym }  =>  :environment do |t, args|
    args.with_defaults(:'ASINList.ASIN.1' => 'B002DYJTVW', :'ASINList.ASIN.2' => 'B0018KVHJO') if not args[:'ASINList.ASIN.1']

    response = mws.products.get_lowest_offer_listings_for_ASIN args

    pp response
  end

  desc "Categories"
  task :categories, [:asin]  => :environment do |t, args|
    args.with_defaults(asin: 'B002DYJTVW')

    response = mws.products.get_product_categories_for_ASIN ASIN: args.asin

    pp response
  end

  def mws
    @mws ||= MWS.new(aws_access_key_id: ENV['AWS_ID'],
                     secret_access_key: ENV['AWS_KEY'],
                     seller_id: ENV['MERCHANT_ID'],
                     marketplace_id: ENV['MARKETPLACE_ID'])
  end


end
