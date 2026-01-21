# Changelog

## [Unreleased]

### Added
- **Policy Scopes**: Filter collections based on user permissions
  - `policy_scope(Model, Query)` helper in actions
  - `Scope` inner class pattern for policies
  - Support for custom scope queries

- **Testing Helpers**: Comprehensive spec helpers for testing policies
  - `assert_permit` and `assert_forbid` macros
  - `describe_policy` and `test_crud_permissions` helper macros
  - Example-based testing utilities

- **Verification Hooks**: Ensure authorization is performed
  - `verify_authorized` and `verify_policy_scoped` methods
  - `skip_authorization` and `skip_policy_scope` to bypass checks
  - Automatic tracking of authorization status

- **Headless Policies**: Support for non-model based authorization
  - `authorize(:symbol)` for policies without specific records
  - Useful for dashboard, admin panel authorization

- **Namespaced Policies**: Organize policies under modules
  - Support for `Admin::PostPolicy` style policies
  - Use with `authorize(object: post, policy: Admin::PostPolicy)`

- **View Helpers**: Authorization helpers for Lucky pages
  - `can?` and `cannot?` helpers
  - `show_if_authorized` and `hide_if_unauthorized` blocks
  - `policy` and `policy_scope` helpers for views

- **Permitted Attributes**: Control mass assignment
  - `permitted_attributes(object)` helper
  - `permitted_attributes_for_action(object, :update)` for action-specific attributes
  - Policy methods for defining allowed parameters

- **Enhanced Error Messages**: More context in authorization errors
  - Error messages include policy class and action attempted
  - Contextual information about the failed authorization

- **Policy Helper Methods**: Additional utilities in actions
  - `policy(object)` and `policy!(object)` to get policy instances
  - `pundit_user` customization point for non-standard user methods

- **Custom Error Classes**: New exception types
  - `NotDefinedError` for missing policies
  - `AuthorizationNotPerformedError` for verification failures
  - `PolicyScopingNotPerformedError` for scope verification

### Changed
- Improved error messages to include context about what action failed
- Enhanced macro system for better Crystal compatibility

### Fixed
- Crystal type system compatibility improvements
- Better handling of nil users and records

## Previous versions

[Previous changelog content...]