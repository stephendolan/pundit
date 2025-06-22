module Pundit
  module SpecHelpers
    # Helper methods for testing Pundit policies in Crystal specs
    #
    # Example usage:
    #   describe PostPolicy do
    #     it "permits update for post owner" do
    #       user = User.new(id: 1)
    #       post = Post.new(user_id: 1)
    #       policy = PostPolicy.new(user, post)
    #
    #       policy.update?.should be_true
    #     end
    #   end

    # Test that a policy permits an action
    macro assert_permit(policy_class, user, record, action)
      %policy = {{policy_class}}.new({{user}}, {{record}})
      %result = %policy.{{action.id}}

      unless %result
        raise "Expected {{policy_class}} to permit {{action}} for user: #{{{user}}.inspect}, record: #{{{record}}.inspect}"
      end

      %result
    end

    # Test that a policy forbids an action
    macro assert_forbid(policy_class, user, record, action)
      %policy = {{policy_class}}.new({{user}}, {{record}})
      %result = %policy.{{action.id}}

      if %result
        raise "Expected {{policy_class}} to forbid {{action}} for user: #{{{user}}.inspect}, record: #{{{record}}.inspect}"
      end

      !%result
    end

    # Test policy scope results
    def assert_scope(scope_class, user, base_scope, &)
      scope = scope_class.new(user, base_scope)
      result = scope.resolve

      yield result
    end

    # Macro to simplify policy testing
    macro test_policy(policy_class, user, record)
      describe {{policy_class}} do
        let(:policy) { {{policy_class}}.new({{user}}, {{record}}) }

        {{yield}}
      end
    end

    # Macro to test standard CRUD permissions
    macro test_crud_permissions(policy_class, permissions = {} of Symbol => Bool)
      {% for action, allowed in permissions %}
        it {{ (allowed ? "permits " : "forbids ") + action.stringify }} do
          policy.{{ action.id }}.should eq({{ allowed }})
        end
      {% end %}
    end

    # Example macro for testing a full policy
    macro describe_policy(policy_class)
      describe {{policy_class}} do
        # Helper to create policy instances
        def policy_for(user, record = nil)
          {{policy_class}}.new(user, record)
        end

        {{yield}}
      end
    end

    # Helper for testing permitted attributes
    macro test_permitted_attributes(policy, expected_attrs)
      it "permits correct attributes" do
        {{policy}}.permitted_attributes.should eq({{expected_attrs}})
      end
    end
  end
end
