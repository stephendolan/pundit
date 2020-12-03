# A set of helpers that can be included in your Lucky `BrowserAction` and made available to all child actions.
module Pundit::ActionHelpers(T)
  # The `authorize` method can be added to any action to determine whether or not the `current_user` can take that action.
  #
  # In its simplest form, you don't have to provide any parameters:
  #
  # ```
  # class Books::Index < BrowserAction
  #   get "/books" do
  #     authorize
  #
  #     html Books::IndexPage, books: BooksQuery.new
  #   end
  # end
  # ```
  #
  # This is equivalent to replacing `authorize` with `BookPolicy.new(current_user).index? || raise Pundit::NotAuthorizedError`
  macro authorize(object = nil, policy = nil, query = nil)
    # Split up the calling class to make it easier to work with
    {% caller_class_array = @type.stringify.split("::") %}

    # First, get the plural base class.
    # For `Store::Books::Index`, this yields `Store::Books`
    {% caller_class_base_plural = caller_class_array[0..-2].join("::") %}

    # Next, singularize that base class.
    # For `Store::Books`, this yields `Store::Book`
    {% caller_class_base_singular = run("./run_macros/singularize.cr", caller_class_base_plural) %}

    # Finally, turn that base class into a policy.
    # For `Store::Book`, this yields `Store::BookPolicy`
    policy_class = {{ caller_class_base_singular.id }}Policy

    # Accept the override if a policy class has been manually provied
    {% if policy %}
      policy_class = {{ policy }}
    {% end %}

    # Pluck the action from the calling class and turn it into a policy method.
    # For `Store::Books::Index`, this yields `index?`
    {% method_name = (caller_class_array.last.underscore + "?").id %}

    # Accept the override if a policy method has been manually provied
    {% if query %}
      {% method_name = query.id %}
    {% end %}

    # Finally, call the policy method.
    # For `authorize` within `Store::Books::Index`, this calls `Store::BookPolicy.new(current_user, nil).index?`
    is_authorized = policy_class.new(current_user, {{ object }}).{{ method_name }}

    if is_authorized
      {{ object }} || is_authorized
    else
      raise Pundit::NotAuthorizedError.new
    end
  end

  # Pundit needs to leverage the `current_user` method for implicit authorization checks
  abstract def current_user : T?
end
