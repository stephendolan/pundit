require "spec"
require "../src/pundit"

# Define a test user class for all specs to use
class TestUser
  property id : Int32

  def initialize(@id : Int32 = 1)
  end
end

# Create the User alias that Pundit expects
alias User = TestUser
