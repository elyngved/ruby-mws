module MWS
  class MWSException < StandardError
  end

  class MissingConnectionOptions < MWSException
  end
end