module MWS

  class MWSException < StandardError
  end

  class MissingConnectionOptions < MWSException
  end

  class NoNextToken < MWSException
  end

end