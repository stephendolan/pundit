require "./spec_helper"

describe "Pundit Errors" do
  describe Pundit::NotAuthorizedError do
    it "has a default message" do
      error = Pundit::NotAuthorizedError.new
      error.message.should eq "Action not permitted"
    end

    it "accepts a custom message" do
      error = Pundit::NotAuthorizedError.new("Custom error message")
      error.message.should eq "Custom error message"
    end

    it "stores policy information" do
      error = Pundit::NotAuthorizedError.new(
        policy: "UserPolicy",
        query: "update?",
        record: "User"
      )
      error.policy.should eq "UserPolicy"
      error.query.should eq "update?"
      error.record.should eq "User"
    end

    it "allows nil values for optional parameters" do
      error = Pundit::NotAuthorizedError.new
      error.policy.should be_nil
      error.query.should be_nil
      error.record.should be_nil
    end

    it "combines custom message with metadata" do
      error = Pundit::NotAuthorizedError.new(
        "You cannot update this user",
        policy: "UserPolicy",
        query: "update?",
        record: "User"
      )
      error.message.should eq "You cannot update this user"
      error.policy.should eq "UserPolicy"
    end
  end

  describe Pundit::NotDefinedError do
    it "can be raised with a message" do
      error = Pundit::NotDefinedError.new("Policy not found")
      error.message.should eq "Policy not found"
    end

    it "inherits from Exception" do
      error = Pundit::NotDefinedError.new
      error.should be_a(Exception)
    end
  end

  describe Pundit::AuthorizationNotPerformedError do
    it "includes the action name in the message" do
      error = Pundit::AuthorizationNotPerformedError.new("Users::Index")
      error.message.should eq "Users::Index has not performed authorization"
    end

    it "inherits from Exception" do
      error = Pundit::AuthorizationNotPerformedError.new("SomeAction")
      error.should be_a(Exception)
    end
  end

  describe Pundit::PolicyScopingNotPerformedError do
    it "includes the action name in the message" do
      error = Pundit::PolicyScopingNotPerformedError.new("Posts::Index")
      error.message.should eq "Posts::Index has not performed policy scoping"
    end

    it "inherits from Exception" do
      error = Pundit::PolicyScopingNotPerformedError.new("SomeAction")
      error.should be_a(Exception)
    end
  end
end
