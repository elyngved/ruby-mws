module MWS
  module API

    class BinaryResponse < Struct.new(:body)

      def self.parse(response, name, params)
        new(response.parsed_response)
      end

    end

  end
end