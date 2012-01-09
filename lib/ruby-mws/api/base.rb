# This class serves as a parent class to the API classes.
# It shares connection handling, query string building, ?? among the models.

module MWS
  module API

    class Base
      include HTTParty
      debug_output $stderr  # only in development
      format :xml
      headers "User-Agent"   => "ruby-mws gem/#{MWS::VERSION} (Language=Ruby/1.9.3)"
      headers "Content-Type" => "text/xml"


      def initialize(connection)
        @connection = connection
        self.class.base_uri "https://#{connection.host}"
      end

      def self.def_request(name, *options)
        self.class_eval %Q{
          def #{name}(params={})
            send_request(:#{name}, params, #{options.first})
          end
        }
      end

      def send_request(name, params, options)
        params = [params, options, @connection.to_hash].inject :merge
        
        # default value handling
        params[:action]            ||= name.to_s.camelize
        params[:signature_method]  ||= 'HmacSHA256'
        params[:signature_version] ||= '2'
        params[:timestamp]         ||= Time.now.iso8601
        params[:version]           ||= '2009-01-01'

        query = Query.new params

        # construct query string
        puts "canonical_query"
        puts query.canonical
        puts ''

        puts "signature"
        puts query.signature
        puts ''

        puts 'url'
        puts query.request_uri
        puts ''

        pp self.class.get(query.request_uri)
      end

    end

  end
end