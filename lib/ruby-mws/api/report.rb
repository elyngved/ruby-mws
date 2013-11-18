module MWS
  module API

    class Report < Base
      def_request [:request_report],
                  :verb => :post,
                  :uri => '/',
                  :version => '2009-01-01'

      def_request [:get_report],
                  :verb => :get,
                  :uri => '/',
                  :version => '2009-01-01'

      def_request [:get_report_request_list, :get_report_request_list_by_next_token],
                  :verb => :get,
                  :uri => '/',
                  :version => '2009-01-01'
    end

  end
end