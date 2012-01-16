module MWS
  module API

    class Response < Hashie::Rash
      
      def self.parse(hash, name, params)
        rash = self.new(hash)
        raise BadResponseError, "received non-matching response type #{rash.keys}" if rash["#{name}_response"].nil?
        rash = rash[rash.keys.first]

        if rash["#{name}_result"]
          rash = rash["#{name}_result"]
          params[:mods].each {|mod| mod.call(rash) } if params[:mods]
          rash
        end
      end

    end

  end
end