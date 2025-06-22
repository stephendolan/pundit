module Pundit
  class PolicyScopingNotPerformedError < Exception
    def initialize(action : String)
      super("#{action} has not performed policy scoping")
    end
  end
end
