ruby-mws
========

by Erik Lyngved

### Read me!

ruby-mws is a Ruby gem that wraps the Amazon Marketplace Web Service (MWS) API. Right now it only supports Amazon's Order and Inventory APIs.

I made this gem for my own purposes, and it's not fully featured. Pull requests or bug reports are always welcome.

Quick Start
-----------

To quickly test your connection to the service without credentials, you can ping the server, which returns server time in UTC:

    MWS::Base.server_time

### Initialization

Pass in your developer account credentials. All four params below are required.

    mws = MWS.new (:aws_access_key_id => "AKIAIFKEXAMPLE4WZHHA",
      :secret_access_key => "abc123def456/SECRET/+ghi789jkl",
      :seller_id => "A27WEXAMPLEBXY",
      :marketplace_id => "ATVPDKIKX0DER")

### Requests

We'll use the Orders API to retrieve recently updated orders.

    # Retrieve all orders updated within the last 4 hours
    response = mws.orders.list_orders :last_updated_after => 4.hours.ago   # ActiveSupport time helper

(All datetime fields accept Time or DateTime objects, as well as strings in iso8601 format.)

### Responses

Response objects inherit [Hashie](http://github.com/intridea/hashie) for easy access and [Rash](http://github.com/tcocca/rash) to convert Amazon's CamelCase convention to underscore. So you're just left with plain ol' Ruby goodness.

Let's parse our response to view the orders and any other data returned.

    response.orders.first   # => { "amazon_order_id" => "002-EXAMPLE-0031387",
                            #      "purchase_date" => "2012-01-13T19:11:46.000Z",
                            #      ... }

Response objects are accessible in Hash or method notation.

    response.orders == response[:orders]   # => true

Use `keys` and `has_key?` to discover what's in the response.

    response.keys   # => ["last_updated_before", "orders"]
    response.has_key? :last_updated_before   # => true

### NextToken requests

For responses with long lists of data, results are returned from the service in pages (usually 100 per page). Example:

    response = mws.orders.list_orders :last_updated_after => 1.week.ago   # returns 100 orders & next_token

Here, there are more orders to be returned. You can call `has_next?` on the same API instance to see if the last response returned has a next page. If so, calling `next` will make the request for the next page.

    mws.orders.has_next?   # => true
    next_response = mws.orders.next   # returns next page of orders

Repeat as necessary. You can keep calling `next` on the API instance as long as `has_next?` returns true.

Or if you need to, you can save `next_token` and go about the manual way as per Amazon's docs:

    next_response = mws.orders.list_orders_by_next_token :next_token => response.next_token

***

API
---

    @mws = MWS.new(authentication_hash)   # initialize the connection object (see above)

This object can be used to access all API services. Below are examples on how to make the different requests that are available so far. Refer to the [Amazon MWS Reference Docs](https://developer.amazonservices.com/) for available fields for each request.

### Orders API

* ListOrders - Gets orders by time range and other parameters

    `@mws.orders.list_orders :last_updated_after => Time.now-4.hours, :order_status => 'Shipped'`

* GetOrder - Gets orders by Amazon order ID

    `@mws.orders.get_order :amazon_order_id => "002-EXAMPLE-0031387"`

    `:amazon_order_id` can be an array to retrieve multiple orders.

* ListOrderItems - Gets order items for one order ID (only one order at a time here)

    `@mws.orders.list_order_items :amazon_order_id => "002-EXAMPLE-0031387"`

### Fulfillment Inventory API

* ListInventorySupply - Returns availability of inventory, only returns items based on list of SKUs or last change date

    `@mws.inventory.list_inventory_supply :seller_skus => ['PF-5VZN-04XR', 'V4-03EY-LAL1', 'OC-TUKC-031P']`
    `@mws.inventory.list_inventory_supply :query_start_date_time => Time.now-1.day`

### Reports API

* RequestReport - Used to submit a request for a report by [report type](http://docs.developer.amazonservices.com/en_US/reports/Reports_ReportType.html). Returns report request info.

    `@mws.reports.request_report :report_type => "_GET_FBA_FULFILLMENT_CUSTOMER_RETURNS_DATA_", :start_date => 1.day.ago, :end_date => Time.now`

* GetReportRequestList - Returns a list of the most recently requested reports. Use `report_request_id` to find the status of your report. Once `report_processing_status` for your request is "_DONE_", use `generated_report_id` to get your results.

    `@mws.reports.get_report_request_list`

* GetReport - Used to request a report by report ID. All reports are currently returned as a flat file string.

    `@mws.reports.get_report :report_id => '11223344'`

Testing
-------

Add the file `spec/credentials.yml` that looks like

```
aws_access_key_id: '[access key]'
secret_access_key: '[secret access key]'
seller_id: '[seller id]'
marketplace_id: '[marketplace id]'
```

Then run `bundle exec rspec spec/`

There's still work and research to be done on how to integrate our changes in with the author's. Because we're using different credentials than the author and there are hardcodede order ids in the specs we'll never have all the specs passing for all of us.
