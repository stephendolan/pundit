# A set of helpers that can be included in your Lucky `BrowserAction` and made available to all child actions.
module Pundit::ActionHelpers(T)
  # Track whether authorization has been performed
  macro included
    property? pundit_policy_authorized : Bool = false
    property? pundit_policy_scoped : Bool = false
  end

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
    {% if object && object.is_a?(SymbolLiteral) %}
      # Handle headless policies (symbol-based authorization)
      {% policy_name = object.id.stringify.capitalize + "Policy" %}
      policy_class = {{policy_name.id}}

      {% if query %}
        {% method_name = query.id %}
      {% else %}
        # Extract method name from calling class for headless policies
        {% caller_class_array = @type.stringify.split("::") %}
        {% method_name = (caller_class_array.last.underscore + "?").id %}
      {% end %}

      # Call the policy method for headless policy
      is_authorized = policy_class.new(current_user).{{ method_name }}
    {% elsif object && object.is_a?(ArrayLiteral) && object.size == 2 %}
      # Handle namespaced policies with explicit policy class
      # Usage: authorize(object: post, policy: Admin::PostPolicy)
      # This is the recommended approach for namespaced policies in Crystal
      raise "For namespaced policies, use authorize(object: record, policy: Namespace::RecordPolicy) instead"
    {% else %}
      # Split up the calling class to make it easier to work with
      {% caller_class_array = @type.stringify.split("::") %}

      # First, get the plural base class.
      # For `Store::Books::Index`, this yields `Store::Books`
      {% caller_class_base_plural = caller_class_array[0..-2].join("::") %}

      # Next, singularize that base class.
      # For `Store::Books`, this yields `Store::Book`
      {% caller_class_base_singular = run("./run_macros/singularize.cr", caller_class_base_plural) %}

      # Finally, turn that base class into a policy.
      # For `Store::Book`, this yields `Store::BookPolicy`.
      # Accepts an override if a policy class has been manually provied
      policy_class = {% if policy %}
        {{ policy }}
      {% else %}
        {{ caller_class_base_singular.id }}Policy
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
    {% end %}

    # Mark that authorization has been performed
    self.pundit_policy_authorized = true

    if is_authorized
      {{ object }} || is_authorized
    else
      {% if object %}
        raise Pundit::NotAuthorizedError.new("not allowed to #{{{ method_name.stringify.gsub(/\?$/, "") }}} this #{{{ object }}.class}")
      {% else %}
        raise Pundit::NotAuthorizedError.new("not allowed to #{{{ method_name.stringify.gsub(/\?$/, "") }}} #{policy_class}")
      {% end %}
    end
  end

  # Pundit needs to leverage the `current_user` method for implicit authorization checks
  abstract def current_user : T?

  # Returns an authorization scope for the given record class
  macro policy_scope(record_class, policy_class = nil)
    # Mark that a policy scope has been used
    self.pundit_policy_scoped = true

    {% if policy_class %}
      {{policy_class.id}}::Scope.new(current_user, {{record_class}}.query).resolve
    {% else %}
      {% policy_name = record_class.id.stringify.split("::").last + "Policy" %}
      {{policy_name.id}}::Scope.new(current_user, {{record_class}}.query).resolve
    {% end %}
  end

  # Returns a policy instance for the given object
  macro policy(object)
    {% if object.is_a?(Symbol) %}
      {% policy_name = object.id.stringify.capitalize + "Policy" %}
      {{policy_name.id}}.new(current_user)
    {% else %}
      {% object_class = object.id.stringify.split("::").last %}
      {% policy_name = object_class + "Policy" %}
      {{policy_name.id}}.new(current_user, {{object}})
    {% end %}
  end

  # Returns a policy instance for the given object, raising if not found
  macro policy!(object)
    policy = policy({{object}})
    unless policy
      raise Pundit::NotDefinedError.new("Unable to find policy for `#{{{object}}.class}`")
    end
    policy
  end

  # Verifies that authorization has been performed
  def verify_authorized
    unless pundit_policy_authorized?
      raise Pundit::AuthorizationNotPerformedError.new(self.class.name)
    end
  end

  # Verifies that policy scoping has been performed
  def verify_policy_scoped
    unless pundit_policy_scoped?
      raise Pundit::PolicyScopingNotPerformedError.new(self.class.name)
    end
  end

  # Skip authorization verification
  def skip_authorization
    self.pundit_policy_authorized = true
  end

  # Skip policy scope verification
  def skip_policy_scope
    self.pundit_policy_scoped = true
  end

  # Allow customization of the user object used for authorization
  def pundit_user
    current_user
  end

  # Get permitted attributes from a policy
  #
  # Example:
  #   allowed_params = permitted_attributes(post)
  #   SavePost.create(params.select(allowed_params)) do |operation, post|
  #     # ...
  #   end
  macro permitted_attributes(object, policy_class = nil)
    {% if policy_class %}
      policy = {{policy_class.id}}.new(current_user, {{object}})
    {% else %}
      {% object_class = object.id.stringify.split("::").last %}
      {% policy_name = object_class + "Policy" %}
      policy = {{policy_name.id}}.new(current_user, {{object}})
    {% end %}

    if policy.responds_to?(:permitted_attributes)
      policy.permitted_attributes
    else
      raise "#{policy.class} does not implement permitted_attributes"
    end
  end

  # Get permitted attributes for a specific action
  #
  # Example:
  #   allowed_params = permitted_attributes_for_action(post, :update)
  macro permitted_attributes_for_action(object, action, policy_class = nil)
    {% if policy_class %}
      policy = {{policy_class.id}}.new(current_user, {{object}})
    {% else %}
      {% object_class = object.id.stringify.split("::").last %}
      {% policy_name = object_class + "Policy" %}
      policy = {{policy_name.id}}.new(current_user, {{object}})
    {% end %}

    {% method_name = "permitted_attributes_for_" + action.id.stringify %}

    if policy.responds_to?({{method_name.symbolize}})
      policy.{{method_name.id}}
    elsif policy.responds_to?(:permitted_attributes)
      policy.permitted_attributes
    else
      raise "#{policy.class} does not implement {{method_name}} or permitted_attributes"
    end
  end
end
