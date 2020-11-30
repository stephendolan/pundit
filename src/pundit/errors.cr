module Pundit
  class Error < Exception
  end

  class NotAuthorizedError < Error
    include Lucky::RenderableError

    def initialize
      super("Action not permitted")
    end

    def renderable_status : Int32
      401
    end

    def renderable_message : String
      "You're not allowed to access that action for that resource."
    end
  end
end
