require "./spec_helper"

class Post; end

class PostPolicy < ApplicationPolicy(Post)
  def publish?
    !!(user && record)
  end

  def archive?
    !!user
  end

  class Scope < ApplicationPolicy::Scope
    @user : User?
    @scope : Array(Post)

    def initialize(@user : User?, @scope : Array(Post))
    end

    def resolve
      if user
        scope
      else
        [] of Post
      end
    end
  end
end

describe ApplicationPolicy do
  describe "initialization" do
    it "accepts a user and a record" do
      user = TestUser.new
      post = Post.new
      policy = PostPolicy.new(user, post)
      policy.user.should eq user
      policy.record.should eq post
    end

    it "accepts a nil user" do
      post = Post.new
      policy = PostPolicy.new(nil, post)
      policy.user.should be_nil
      policy.record.should eq post
    end

    it "accepts a nil record" do
      user = TestUser.new
      policy = PostPolicy.new(user, nil)
      policy.user.should eq user
      policy.record.should be_nil
    end

    it "accepts both nil user and nil record" do
      policy = PostPolicy.new(nil, nil)
      policy.user.should be_nil
      policy.record.should be_nil
    end

    it "defaults record to nil when not provided" do
      user = TestUser.new
      policy = PostPolicy.new(user)
      policy.user.should eq user
      policy.record.should be_nil
    end
  end

  describe "default methods" do
    it "returns false for index? by default" do
      policy = PostPolicy.new(nil)
      policy.index?.should be_false
    end

    it "returns false for show? by default" do
      policy = PostPolicy.new(nil)
      policy.show?.should be_false
    end

    it "returns false for create? by default" do
      policy = PostPolicy.new(nil)
      policy.create?.should be_false
    end

    it "delegates new? to create?" do
      policy = PostPolicy.new(nil)
      policy.new?.should eq policy.create?
    end

    it "returns false for update? by default" do
      policy = PostPolicy.new(nil)
      policy.update?.should be_false
    end

    it "delegates edit? to update?" do
      policy = PostPolicy.new(nil)
      policy.edit?.should eq policy.update?
    end

    it "returns false for delete? by default" do
      policy = PostPolicy.new(nil)
      policy.delete?.should be_false
    end
  end

  describe "custom methods" do
    it "can be defined in subclasses" do
      user = TestUser.new
      post = Post.new
      policy = PostPolicy.new(user, post)
      policy.publish?.should be_true
    end

    it "can access user and record in custom methods" do
      user = TestUser.new
      policy = PostPolicy.new(user, nil)
      policy.archive?.should be_true

      policy_no_user = PostPolicy.new(nil, nil)
      policy_no_user.archive?.should be_false
    end
  end

  describe "Scope" do
    it "can be defined in policy subclasses" do
      # The base ApplicationPolicy.scope returns ApplicationPolicy::Scope
      # Each policy subclass has its own Scope inner class
      PostPolicy::Scope.should be < ApplicationPolicy::Scope
    end

    it "initializes with user and scope" do
      user = TestUser.new
      posts = [Post.new, Post.new]
      scope = PostPolicy::Scope.new(user, posts)
      scope.user.should eq user
      scope.scope.should eq posts
    end

    it "can implement custom resolve logic" do
      user = TestUser.new
      posts = [Post.new, Post.new]
      scope = PostPolicy::Scope.new(user, posts)
      scope.resolve.should eq posts

      scope_no_user = PostPolicy::Scope.new(nil, posts)
      scope_no_user.resolve.should eq [] of Post
    end
  end
end
