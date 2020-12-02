require "lucky_cli"

class Pundit::InitTemplate < Teeplate::FileTree
  directory "#{__DIR__}/templates/init"

  @user_model : String

  def initialize(@user_model)
  end
end

class Pundit::Init < LuckyCli::Task
  summary "Generate the default ApplicationPolicy for Pundit"
  name "pundit.init"

  arg :user_model,
    "Specify another User model",
    shortcut: "-u",
    optional: true,
    format: /^[A-Z]/

  def call
    model = user_model || "User"

    template = InitTemplate.new(model)
    template.render ".", interactive: true, list: true, color: true
  end
end
