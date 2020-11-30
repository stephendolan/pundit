module Pundit::ActionHelpers
  macro authorize(object = nil, policy_class_override = nil, method_name_override = nil)
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
    {% if policy_class_override %}
      policy_class = {{ policy_class_override }}
    {% end %}

    # Pluck the action from the calling class and turn it into a policy method.
    # For `Store::Books::Index`, this yields `index?`
    {% method_name = (caller_class_array.last.underscore + "?").id %}

    # Accept the override if a policy method has been manually provied
    {% if method_name_override %}
      {% method_name = method_name_override.id %}
    {% end %}

    # Finally, call the policy method.
    # For `authorize` within `Store::Books::Index`, this calls `Store::BookPolicy.new(current_user, nil).index?`
    policy_class.new(current_user, {{ object }}).{{ method_name }} || raise Pundit::NotAuthorizedError.new
  end

  # We need to leverage the `current_user` method for implicit authorization checks
  abstract def current_user : T?
end
