module MWS
  module API

    class Response < Hashie::Rash

      def self.parse(body, name, params)
        return body unless body.is_a?(Hash)

        rash = self.new(body)
        if !rash.keys.nil? && rash.keys.first == "amazon_envelope"
          rash
        else
          raise BadResponseError, "received non-matching response type #{rash.keys}" if rash["#{name}_response"].nil? 
          rash = rash["#{name}_response"]

          if rash = rash["#{name}_result"]
            # only runs mods if correct result is present
            params[:mods].each {|mod| mod.call(rash) } if params[:mods]
            rash
          end
        end
      end

      def self.handle_error_response(error)
        msg = "#{error.code}: #{error.message}"
        msg << " -- #{error.detail}" unless error.detail.nil?
        raise ErrorResponse, msg
      end

    end

  end
end
