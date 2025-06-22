require "./spec_helper"

describe Pundit::VERSION do
  it "is defined" do
    Pundit::VERSION.should_not be_nil
  end

  it "is a string" do
    Pundit::VERSION.should be_a(String)
  end

  it "is not empty" do
    Pundit::VERSION.should_not eq("")
  end

  it "follows semantic versioning format" do
    # Basic check for semantic versioning pattern (e.g., "1.0.0" or "1.0.0-dev")
    Pundit::VERSION.should match(/^\d+\.\d+\.\d+(-\w+)?$/)
  end
end
