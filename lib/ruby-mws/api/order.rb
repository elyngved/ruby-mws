module MWS
  module API

    class Order < Base

      def_request :list_orders, :verb => :get, :uri => '/Orders/2011-01-01',
        :version => '2011-01-01'

    end

  end
end