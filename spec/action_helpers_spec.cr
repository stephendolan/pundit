require "./spec_helper"

class Book; end

class User; end

class OverridePolicy < ApplicationPolicy(Book)
  def pass?
    true
  end

  def fail?
    false
  end
end

class BookPolicy < ApplicationPolicy(Book)
  def pass?
    true
  end

  def fail?
    false
  end
end

class ActionMock
  include Pundit::ActionHelpers(User)

  def current_user : User
    User.new
  end
end

macro define_mock_action(pass_or_fail)
  class Books::{{ pass_or_fail }} < ActionMock
    def action_no_args
      authorize
    end

    def action_with_object(book)
      authorize(object: book)
    end

    def action_with_policy(policy)
      authorize(policy: policy)
    end

    def action_with_query_string
      authorize(query: "#{{{ pass_or_fail.stringify.underscore }}}?")
    end

    def action_with_query_symbol
      authorize(query: :{{ pass_or_fail.stringify.underscore.id }}?)
    end
  end
end

define_mock_action(Pass)
define_mock_action(Fail)

describe Pundit::ActionHelpers do
  describe "#authorize" do
    describe "passing nothing" do
      it "returns true when authorization passes" do
        Books::Pass.new.action_no_args.should be_true
      end

      it "raises when authorization fails" do
        expect_raises Pundit::NotAuthorizedError do
          Books::Fail.new.action_no_args
        end
      end
    end

    describe "passing an object" do
      it "returns the object when authorization passes" do
        book = Book.new
        Books::Pass.new.action_with_object(book).should eq book
      end

      it "raises when authorization fails" do
        expect_raises Pundit::NotAuthorizedError do
          book = Book.new
          Books::Fail.new.action_with_object(book)
        end
      end
    end

    describe "passing a policy override" do
      it "returns true when authorization passes" do
        Books::Pass.new.action_with_policy(OverridePolicy).should be_true
      end

      it "raises when authorization fails" do
        expect_raises Pundit::NotAuthorizedError do
          Books::Fail.new.action_with_policy(OverridePolicy)
        end
      end
    end

    describe "passing a query override" do
      context "as a symbol" do
        it "returns true when authorization passes" do
          Books::Pass.new.action_with_query_symbol.should be_true
        end

        it "raises when authorization fails" do
          expect_raises Pundit::NotAuthorizedError do
            Books::Fail.new.action_with_query_symbol
          end
        end
      end

      context "as a string" do
        it "returns true when authorization passes" do
          Books::Pass.new.action_with_query_string.should be_true
        end

        it "raises when authorization fails" do
          expect_raises Pundit::NotAuthorizedError do
            Books::Fail.new.action_with_query_string
          end
        end
      end
    end
  end
end
