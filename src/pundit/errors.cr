module Pundit
  class Error < Exception
  end

  class NotAuthorizedError < Error
    def initialize
      super("Action not permitted")
    end
  end
end
