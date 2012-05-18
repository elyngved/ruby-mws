module MWS
  module API

    class BinaryParser < HTTParty::Parser
      SupportedFormats.merge!({ "application/octet-stream" => :binary })

      protected

      def binary
        body
      end

    end

  end
end
