module Pundit
  # The exception that is raised when authorization fails for a policy check
  class NotAuthorizedError < Exception
    def initialize
      super("Action not permitted")
    end
  end
end
