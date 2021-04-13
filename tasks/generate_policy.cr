require "lucky_task"
require "teeplate"

class Pundit::GeneratePolicyTemplate < Teeplate::FileTree
  directory "#{__DIR__}/templates/policy"

  @policy_model : String
  @file : String

  def initialize(@policy_model)
    @file = @policy_model.underscore.gsub("::", "/")
  end
end

class Pundit::GeneratePolicy < LuckyTask::Task
  summary "Generate a Pundit policy for a model or resource"
  name "gen.policy"

  positional_arg :policy_model,
    "Specify your policy model",
    format: /^[A-Z]/

  def call
    template = GeneratePolicyTemplate.new(policy_model)
    template.render ".", interactive: true, list: true, color: true
  end
end
