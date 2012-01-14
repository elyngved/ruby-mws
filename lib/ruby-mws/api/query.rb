module MWS
  module API

    class Query

      def initialize(params)
        @params = params
      end

      def canonical
        [@params[:verb].to_s.upcase, @params[:host], @params[:uri], build_sorted_query].join("\n")
      end

      def signature
        digest = OpenSSL::Digest::Digest.new('sha256')
        key = @params[:secret_access_key]
        Base64.encode64(OpenSSL::HMAC.digest(digest, key, canonical)).chomp
      end

      def request_uri
        "https://" << @params[:host] << @params[:uri] << '?' << build_sorted_query(signature)
      end

      private
      def build_sorted_query(signature=nil)
        params = @params.dup.delete_if {|k,v| exclude_from_query.include? k}
        params[:signature] = signature if signature
        params.stringify_keys!

        # hack to capitalize AWS in param names
        # TODO: Allow for multiple marketplace ids
        params = Hash[params.map{|k,v| [k.camelize.sub(/Aws/,'AWS').sub(/MarketplaceId/, "MarketplaceId.Id.1"), v]}]

        params = params.sort.map! { |p| "#{p[0]}=#{escape(p[1])}" }
        params.join('&')
      end

      def escape(value)
        value.gsub(/([^a-zA-Z0-9_.~-]+)/) do
          '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
        end
      end

      def exclude_from_query
        [
          :verb,
          :host,
          :uri,
          :secret_access_key,
          :return
        ]
      end

    end

  end
end