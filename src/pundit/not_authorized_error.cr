module Pundit
  # The exception that is raised when authorization fails for a policy check
  class NotAuthorizedError < Exception
    getter policy : String?
    getter query : String?
    getter record : String?

    def initialize(message : String? = nil, @policy : String? = nil, @query : String? = nil, @record : String? = nil)
      super(message || "Action not permitted")
    end
  end
end
