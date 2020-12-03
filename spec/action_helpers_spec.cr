require "./spec_helper"

class Book; end

class User; end

class AlwaysPassPolicy < ApplicationPolicy(Book)
  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def update?
    true
  end

  def delete?
    true
  end
end

class AlwaysFailPolicy < ApplicationPolicy(Book)
end

class BookPolicy < ApplicationPolicy(Book)
  def initialize(@user, @record); end

  def index?
    true
  end

  def create?
    true
  end

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

class Books::Index < ActionMock
  def action(book = nil)
    authorize
  end
end

class Books::Show < ActionMock
  def action(book = nil)
    authorize
  end
end

class Books::Update < ActionMock
  def action(policy = nil)
    authorize(policy: policy)
  end
end

class Books::Create < ActionMock
  def action(book = nil)
    authorize(book)
  end
end

class Books::StringQueryFail < ActionMock
  def action
    authorize(query: "fail?")
  end
end

class Books::StringQueryPass < ActionMock
  def action
    authorize(query: "pass?")
  end
end

class Books::SymbolQueryFail < ActionMock
  def action
    authorize(query: :fail?)
  end
end

class Books::SymbolQueryPass < ActionMock
  def action
    authorize(query: :pass?)
  end
end

describe Pundit::ActionHelpers do
  describe "#authorize" do
    describe "passing nothing" do
      it "returns true when authorization passes" do
        Books::Index.new.action.should eq true
      end

      it "raises when authorization fails" do
        expect_raises Pundit::NotAuthorizedError do
          Books::Show.new.action
        end
      end
    end

    describe "passing an object" do
      it "returns the object when authorization passes" do
        book = Book.new
        Books::Create.new.action(book).should eq book
      end

      it "raises when authorization fails" do
        expect_raises Pundit::NotAuthorizedError do
          book = Book.new
          Books::Show.new.action(book)
        end
      end
    end

    describe "passing a policy override" do
      it "returns true when authorization passes" do
        Books::Update.new.action(AlwaysPassPolicy).should eq true
      end

      it "raises when authorization fails" do
        expect_raises Pundit::NotAuthorizedError do
          Books::Update.new.action(AlwaysFailPolicy)
        end
      end
    end

    describe "passing a query override" do
      context "as a symbol" do
        it "returns true when authorization passes" do
          Books::SymbolQueryPass.new.action.should eq true
        end

        it "raises when authorization fails" do
          expect_raises Pundit::NotAuthorizedError do
            Books::SymbolQueryFail.new.action
          end
        end
      end

      context "as a string" do
        it "returns true when authorization passes" do
          Books::StringQueryPass.new.action.should eq true
        end

        it "raises when authorization fails" do
          expect_raises Pundit::NotAuthorizedError do
            Books::StringQueryFail.new.action
          end
        end
      end
    end
  end
end
