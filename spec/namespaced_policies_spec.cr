require "./spec_helper"

class Post; end

class User; end

module Admin
  class PostPolicy < ApplicationPolicy(Post)
    def index?
      true
    end

    def update?
      user != nil
    end
  end
end

class ActionMock
  include Pundit::ActionHelpers(User)

  def current_user : User?
    User.new
  end
end

class Admin::Posts::Index < ActionMock
  def action_with_namespace
    post = Post.new
    authorize(object: post, policy: Admin::PostPolicy)
  end
end

class Admin::Posts::Update < ActionMock
  def action_with_namespace
    post = Post.new
    authorize(object: post, policy: Admin::PostPolicy)
  end
end

describe "Namespaced policies" do
  describe "#authorize with explicit namespaced policy" do
    it "uses the specified namespaced policy class" do
      result = Admin::Posts::Index.new.action_with_namespace
      result.should be_a(Post)
    end

    it "authorizes correctly with the namespaced policy" do
      result = Admin::Posts::Update.new.action_with_namespace
      result.should be_a(Post)
    end
  end
end
