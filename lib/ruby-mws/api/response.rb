module MWS
  module API

    class Response < Hashie::Rash
      
      def self.parse(hash, name, params)
        rash = self.new(hash)
        handle_error_response(rash["error_response"]["error"]) unless rash["error_response"].nil?
        raise BadResponseError, "received non-matching response type #{rash.keys}" if rash["#{name}_response"].nil?
        rash = rash["#{name}_response"]

        if rash = rash["#{name}_result"]
          # only runs mods if correct result is present
          params[:mods].each {|mod| mod.call(rash) } if params[:mods]
          rash
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