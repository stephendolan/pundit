module Pundit
  module PolicyScope
    macro included
      abstract class Scope
        getter user : User?
        getter scope : Avram::Queryable

        def initialize(@user : User?, @scope : Avram::Queryable)
        end

        abstract def resolve
      end
    end

    macro policy_scope(record_class, user = current_user, policy_class = nil)
      {% if policy_class %}
        {{policy_class.id}}.new({{user}}).scope.new({{user}}, {{record_class}}.query).resolve
      {% else %}
        {% policy_name = record_class.id.stringify.split("::").last + "Policy" %}
        {{policy_name.id}}.new({{user}}).scope.new({{user}}, {{record_class}}.query).resolve
      {% end %}
    end

    macro policy_scope!(record_class, user = current_user, policy_class = nil)
      {% if policy_class %}
        {{policy_class.id}}.new({{user}}).scope.new({{user}}, {{record_class}}.query).resolve
      {% else %}
        {% policy_name = record_class.id.stringify.split("::").last + "Policy" %}
        policy_class = {{policy_name.id}}
        unless policy_class.responds_to?(:new)
          raise Pundit::NotDefinedError.new("Unable to find policy `#{policy_class}` for `{{record_class}}`")
        end
        policy_class.new({{user}}).scope.new({{user}}, {{record_class}}.query).resolve
      {% end %}
    end
  end
end
