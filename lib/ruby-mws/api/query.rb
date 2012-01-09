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
        puts digest
        key = @params[:secret_access_key]
        puts key
        signature = canonical
        puts signature
        # escape(Base64.encode64("#{OpenSSL::HMAC.digest(digest, key, canonical)}").chomp)

        hmac = OpenSSL::HMAC.digest(digest, key, signature)
        escape([hmac].pack('m').chomp)
        
        # hmac = HMAC::SHA1.new(@params[:secret_access_key])
        # hmac.update(canonical)
        # CGI.escape(Base64.encode64(hmac.digest).chomp)
      end

      def request_uri
        "https://" << @params[:host] << @params[:uri] << '?' << build_sorted_query(signature)
      end

      private
      def build_sorted_query(signature=nil)
        params = @params.dup.delete_if {|k,v| exclude_from_query.include? k}

        ##### for case sensitive (natural byte) sorting:
        params[:signature] = signature if signature
        params.stringify_keys!
        params = Hash[params.map{|k,v| [k.sub(/aws/,'AWS'), v]}] # hack to capitalize AWS in param names
        params = params.sort.map! { |p| "#{p[0].camelize}=#{escape(p[1])}" }
        params << "Signature=#{signature}" if signature  # signature comes last if provided
        params.join('&')

        ##### for case insensitive sorting:
        # a = params.sort
        # a.map! do |p|
        #   p[0] = p[0].to_s.sub /aws/, 'AWS'
        #   "#{p[0].camelize}=#{p[1]}"
        # end
        # a << "Signature=#{signature}" if signature  # signature comes last if provided
        # a.join '&'
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
          :secret_access_key
        ]
      end

    end

  end
end