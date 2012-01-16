ruby-mws
========

Under development
-----------------

This is a Ruby gem that wraps the Amazon Marketplace Web Service (MWS) API. It is still missing many features, but some basic requests are available.

Please use at your own risk. This has not been tested thoroughly and is not guaranteed to work in any capacity. See the LICENSE file for more details.

Quick Start
-----------

### Initialize the connection object

Pass in your developer account credentials. All four params below are required.

    mws = MWS.new {:aws_access_key_id => "AKIAIFKEXAMPLE4WZHHA",
      :secret_access_key => "abc123def456/SECRET/+ghi789jkl",
      :seller_id => "A27WEXAMPLEBXY",
      :marketplace_id => "ATVPDKIKX0DER"}

### Make a request

Let's use the Orders API to retrieve recently updated orders.

    # Retrieve all orders updated within the last 4 hours
    response = mws.orders.list_orders :last_updated_after => Time.now-4.hours   # Rails helper used

(All datetime fields accept Time or DateTime objects, as well as strings in iso8601 format.)

### Parse the response

We can parse our response to view the orders and any other data returned.

    response.orders.first   # => { "amazon_order_id" => "002-EXAMPLE-0031387",
                                   "purchase_date" => "2012-01-13T19:11:46.000Z",
                                   ... }

Response objects are accessible in Hash or method notation.

    response.orders == response[:orders]   # => true

Use `keys` and `has_key?` to discover what's in the response.

    response.keys   # => ["last_updated_before", "orders"]
    response.has_key? :last_updated_before   # => true

### next

For responses with long lists of info, results are returned from the service in pages (usually 100 to a page). If a response has a next page, calling `next` on the same API instance will make a request for the next page. You cam keep calling `next` as long as `has_next?` returns true.

    response = mws.orders.list_orders :last_updated_after => Time.now-1.week   # returns 100 orders

    mws.orders.has_next?   # => true
    next_response = mws.orders.next   # returns next page of orders
    
    mws.orders.has_next?   # => false
    mws.orders.next        # => nil

### Underscore notation

ruby-mws wraps Amazon's CamelCase convention with Ruby-friendly underscore notation. If you are following along with Amazon's MWS Developer Docs, all field names translate

Available Requests
------------------

    @mws = MWS.new(authentication_hash)   # initialize the connection object

### Orders API

* list_orders - gets orders by time frame and other parameters

    `@mws.orders.list_orders :last_updated_after => Time.now-4.hours`

* get_order - gets orders by Amazon order ID

    `@mws.orders.get_order :amazon_order_id => "002-EXAMPLE-0031387"`

    `:amazon_order_id` can be an array to retrieve multiple orders.

* list_order_items - gets order items for one order ID

    `@mws.orders.list_order_items :amazon_order_id => "002-EXAMPLE-0031387"`

### Fulfillment Inventory API

* list_inventory_supply - returns availability of inventory, only returns items based on list of SKUs or last change date

  `@mws.inventory.list_inventory_supply :seller_skus => %w[PF-5VZN-04XR V4-03EY-LAL1 OC-TUKC-031P`
  `@mws.inventory.list_inventory_supply :query_start_date_time => Time.now-1.day`