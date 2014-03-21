module MWS
  module API

    class Query
      UNSAFE_PARAMS = [:mods, :aws_access_key_id, :seller_id, :secret_access_key].freeze

      def initialize(params)
        @params = params
        params[:lists].each do |field,label|
          [params.delete(field)].compact.flatten.each_with_index do |item,i|
            params["#{label}.#{i+1}"] = item
          end
        end unless params[:lists].nil?
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

      # Strips all the "unsafe" keys from the params instance var
      # @return [Hash] cleaned params
      def safe_params
        @params.reject{|key,_| UNSAFE_PARAMS.include? key}
      end

      private
      def build_sorted_query(signature=nil)
        params = @params.dup.delete_if {|k,v| exclude_from_query.include? k}
        params[:signature] = signature if signature
        params.stringify_keys!

        # hack to capitalize AWS in param names
        # TODO: Allow for multiple marketplace ids
        params = Hash[params.map{|k,v| [k.ruby_mws_camelize.sub(/Aws/,'AWS'), v]}]

        params = params.sort.map! { |p| "#{p[0]}=#{process_param(p[1])}" }
        params.join('&')
      end

      def process_param(param)
        case param
        when Time, DateTime
          escape(param.iso8601)
        else
          escape(param.to_s)
        end
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
          :return,
          :lists,
          :mods
        ]
      end

    end

  end
end
