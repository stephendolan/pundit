module Pundit::ActionHelpers
  macro authorize(object = nil, policy_class_override = nil, method_name_override = nil)
    {% caller_class_array = @type.stringify.split("::") %}

    policy_class = {{ caller_class_array[0..-2].join("::").id }}Policy

    {% if policy_class_override %}
      policy_class = {{ policy_class_override }}
    {% end %}

    {% method_name = (caller_class_array.last.underscore + "?").id %}

    {% if method_name_override %}
      {% method_name = method_name_override.id %}
    {% end %}

    policy_class.new(current_user, {{ object }}).{{ method_name }} || raise Pundit::NotAuthorizedError.new
  end

  abstract def current_user : T?
end
