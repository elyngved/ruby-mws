module MWS
  module API

    class Response < Hashie::Rash
      
      def self.parse(hash, name, params)
        rash = self.new(hash)
        handle_error_response(rash["error_response"]["error"]) unless rash["error_response"].nil?

        rash = if rash["#{name}_response"]
          rash["#{name}_response"]
        elsif rash["amazon_envelope"]
          rash["amazon_envelope"]
        else
          raise BadResponseError, "received non-matching response type #{rash.keys}"
        end

        if rash["#{name}_result"]
          rash = rash["#{name}_result"]
          # only runs mods if correct result is present
          params[:mods].each {|mod| mod.call(rash) } if params[:mods]
        end

        rash
      end

      def self.handle_error_response(error)
        msg = "#{error.code}: #{error.message}"
        msg << " -- #{error.detail}" unless error.detail.nil?
        raise ErrorResponse, msg
      end

    end

  end
end