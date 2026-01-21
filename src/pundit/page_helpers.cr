# View helpers for Lucky pages to easily check policies in templates
module Pundit::PageHelpers
  # Check if the current user is authorized to perform an action
  #
  # Example:
  #   if can?(update?, post)
  #     link "Edit", to: Posts::Edit.with(post.id)
  #   end
  macro can?(action, object, policy_class = nil)
    {% if policy_class %}
      {{policy_class.id}}.new(current_user, {{object}}).{{action.id}}
    {% else %}
      {% object_class = object.id.stringify.split("::").last %}
      {% policy_name = object_class + "Policy" %}
      {{policy_name.id}}.new(current_user, {{object}}).{{action.id}}
    {% end %}
  end

  # Check if the current user is NOT authorized to perform an action
  #
  # Example:
  #   if cannot?(delete?, post)
  #     text "You cannot delete this post"
  #   end
  macro cannot?(action, object, policy_class = nil)
    !can?({{action}}, {{object}}, {{policy_class}})
  end

  # Get a policy instance for use in views
  #
  # Example:
  #   policy = policy(post)
  #   if policy.update?
  #     # show update button
  #   end
  macro policy(object, policy_class = nil)
    {% if policy_class %}
      {{policy_class.id}}.new(current_user, {{object}})
    {% else %}
      {% object_class = object.id.stringify.split("::").last %}
      {% policy_name = object_class + "Policy" %}
      {{policy_name.id}}.new(current_user, {{object}})
    {% end %}
  end

  # Get a policy scope for collections
  #
  # Example:
  #   posts = policy_scope(Post, Post::BaseQuery)
  macro policy_scope(model, query = nil, policy_class = nil)
    {% if policy_class %}
      {{policy_class.id}}::Scope.new(current_user, {{query || model + "::BaseQuery"}}.new).resolve
    {% else %}
      {% policy_name = model.id.stringify.split("::").last + "Policy" %}
      {{policy_name.id}}::Scope.new(current_user, {{query || model + "::BaseQuery"}}.new).resolve
    {% end %}
  end

  # Show content only if authorized
  #
  # Example:
  #   show_if_authorized(update?, post) do
  #     link "Edit", to: Posts::Edit.with(post.id)
  #   end
  macro show_if_authorized(action, object, policy_class = nil, &block)
    if can?({{action}}, {{object}}, {{policy_class}})
      {{yield}}
    end
  end

  # Hide content if not authorized
  #
  # Example:
  #   hide_if_unauthorized(delete?, post) do
  #     link "Delete", to: Posts::Delete.with(post.id)
  #   end
  macro hide_if_unauthorized(action, object, policy_class = nil, &block)
    show_if_authorized({{action}}, {{object}}, {{policy_class}}) do
      {{yield}}
    end
  end

  # Requires a current_user method in the page
  abstract def current_user
end
