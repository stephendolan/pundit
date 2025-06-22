module Pundit
  class AuthorizationNotPerformedError < Exception
    def initialize(action : String)
      super("#{action} has not performed authorization")
    end
  end
end
