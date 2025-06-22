require "./spec_helper"
require "../src/pundit/spec_helpers"

class TestRecord; end

class TestRecordPolicy < ApplicationPolicy(TestRecord)
  def show?
    user != nil
  end

  def update?
    user != nil && record != nil
  end

  def delete?
    false
  end

  def permitted_attributes
    if user
      [:title, :body, :published]
    else
      [:title, :body]
    end
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user
        scope
      else
        # Return empty scope
        scope
      end
    end
  end
end

include Pundit::SpecHelpers

describe Pundit::SpecHelpers do
  describe "#assert_permit" do
    it "passes when action is permitted" do
      user = TestUser.new
      record = TestRecord.new
      assert_permit(TestRecordPolicy, user, record, show?).should be_true
    end

    it "raises when action is not permitted" do
      expect_raises(Exception, /Expected TestRecordPolicy to permit delete\?/) do
        user = TestUser.new
        record = TestRecord.new
        assert_permit(TestRecordPolicy, user, record, delete?)
      end
    end
  end

  describe "#assert_forbid" do
    it "passes when action is forbidden" do
      user = TestUser.new
      record = TestRecord.new
      assert_forbid(TestRecordPolicy, user, record, delete?).should be_true
    end

    it "raises when action is permitted" do
      expect_raises(Exception, /Expected TestRecordPolicy to forbid show\?/) do
        user = TestUser.new
        record = TestRecord.new
        assert_forbid(TestRecordPolicy, user, record, show?)
      end
    end
  end

  # Example of using test_crud_permissions macro
  # This would normally be used inside a describe block
  it "demonstrates test_crud_permissions macro usage" do
    user = TestUser.new
    record = TestRecord.new
    policy = TestRecordPolicy.new(user, record)

    # The macro would generate tests like these:
    policy.show?.should be_true
    policy.update?.should be_true
    policy.delete?.should be_false
  end
end
