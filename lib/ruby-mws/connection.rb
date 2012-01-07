module MWS
  class Connection
    attr_reader :access_key, :secret_access_key, :merchant_id, :marketplace_id

    def initialize(options={})
      @access_key        = options[:access_key]
      @secret_access_key = options[:secret_access_key]
      @merchant_id       = options[:merchant_id]
      @marketplace_id    = options[:marketplace_id]

      raise MissingConnectionOptions if [@access_key, @secret_access_key, @merchant_id, @marketplace_id].any? {|option| option.nil?}
    end
  end
end