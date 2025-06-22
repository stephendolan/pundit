# Pundit

![Shard CI](https://github.com/stephendolan/pundit/workflows/Shard%20CI/badge.svg)
[![API Documentation Website](https://img.shields.io/website?down_color=red&down_message=Offline&label=API%20Documentation&up_message=Online&url=https%3A%2F%2Fstephendolan.github.io%2Fpundit%2F)](https://stephendolan.github.io/pundit)
[![GitHub release](https://img.shields.io/github/release/stephendolan/pundit.svg?label=Release)](https://github.com/stephendolan/pundit/releases)

A simple Crystal shard for managing authorization in [Lucky](https://luckyframework.org) applications. Intended to mimic the excellent Ruby [Pundit](https://github.com/varvet/pundit) gem.

This shard is very much still a work in progress. I'm using it in my own production apps, but the API is subject to major breaking changes and reworks until I tag v1.0.

## Lucky Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   # shard.yml
   dependencies:
     pundit:
       github: stephendolan/pundit
   ```

1. Run `shards install`

1. Require the shard in your Lucky application

   ```crystal
   # shards.cr
   require "pundit"
   ```

1. Require the tasks in your Lucky application

   ```crystal
   # tasks.cr
   require "pundit/tasks/**"
   ```

1. Require a new directory for policy definitions

   ```crystal
   # app.cr
   require "./policies/**"
   ```

1. Include the `Pundit::ActionHelpers` module in `BrowserAction`:

   ```crystal
   # src/actions/browser_action.cr
   include Pundit::ActionHelpers(User)
   ```

1. (Optional) Capture `Pundit` exceptions in `src/actions/errors/show.cr` with a new `#render` override:

   ```crystal
   # Capture Pundit authorization exceptions to handle it elegantly
   def render(error : Pundit::NotAuthorizedError)
     if html?
       error_html "Sorry, you're not authorized to access that", status: 401
     else
       error_json "Not authorized", status: 401
     end
   end
   ```

1. Run the initializer to create your `ApplicationPolicy` if you don't want [the default](src/pundit/application_policy.cr):

   ```sh
   lucky pundit.init
   ```

## Usage

### Creating policies

The easiest way to create new policies is to use the built-in Lucky task! After following the steps in the Installation section, simply run `lucky gen.policy Book`, for example, to create a new `BookPolicy` in your application.

Your policies must inherit from the provided [`ApplicationPolicy(T)`](src/pundit/application_policy.cr) abstract class, where `T` is the model you are authorizing against.

For example, the `BookPolicy` we created with `lucky gen.policy Book` might look like this:

```crystal
class BookPolicy < ApplicationPolicy(Book)
  def index?
    # If you want to either allow or deny all visitors, simply return `true` or `false`
    true
  end

  def show?
    # You can reference other methods if you want to share authorization between them
    update?
  end

  def create?
    # Only signed-in users can create books
    return false unless signed_in_user = user
  end

  def update?
    # Only the owner of a book can update it
    return false unless requested_book = record
    
    requested_book.owner == user
  end

  def delete?
    # You can reference other methods if you want to share authorization between them
    update?
  end

  # Define permitted attributes for mass assignment
  def permitted_attributes
    if user.try(&.admin?)
      [:title, :body, :published, :author_id]
    else
      [:title, :body]
    end
  end

  # You can also define action-specific permitted attributes
  def permitted_attributes_for_update
    [:title, :body]
  end

  # Policy Scope for filtering collections
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user
        # Show only user's books or published books
        scope.where(user_id: user.id).or(&.where(published: true))
      else
        # Show only published books to visitors
        scope.where(published: true)
      end
    end
  end
end
```

The following methods are provided in [`ApplicationPolicy`](src/pundit/application_policy.cr):

| Method Name | Default Value |
| ----------- | ------------- |
| `index?`    | `false`       |
| `show?`     | `false`       |
| `create?`   | `false`       |
| `new?`      | `create?`     |
| `update?`   | `false`       |
| `edit?`     | `update?`     |
| `delete?`   | `false`       |

### Authorizing actions

Let's say we have a `Books::Index` action that looks like this:

```crystal
class Books::Index < BrowserAction
  get "/books/index" do
    html IndexPage, books: BookQuery.new
  end
end
```

To use Pundit for authorization, simply add an `authorize` call:

```crystal
class Books::Index < BrowserAction
  get "/books/index" do
    authorize

    html IndexPage, books: BookQuery.new
  end
end
```

Behind the scenes, this is using the action's class name to check whether the `BookPolicy`'s `index?` method is permitted for `current_user`. If the call fails, a `Pundit::NotAuthorizedError` is raised.

The `authorize` call above is identical to writing this:

```crystal
BookPolicy.new(current_user).index? || raise Pundit::NotAuthorizedError.new
```

You can also leverage specific records in your authorization. For example, say we have a `Books::Update` action that looks like this:

```crystal
post "/books/:book_id/update" do
  book = BookQuery.find(book_id)

  SaveBook.update(book, params) do |operation, book|
    redirect Home::Index
  end
end
```

We can add an `authorize` call to check whether or not the user is permitted to update this specific book like this:

```crystal
post "/books/:book_id/update" do
  book = BookQuery.find(book_id)

  authorize(book)

  SaveBook.update(book, params) do |operation, book|
    redirect Home::Index
  end
end
```

### Using Policy Scopes

Policy scopes allow you to filter collections based on what the user is allowed to see:

```crystal
class Books::Index < BrowserAction
  get "/books" do
    # Use policy scope to filter books
    books = policy_scope(Book, BookQuery.new)
    
    html IndexPage, books: books
  end
end
```

### Headless Policies

For actions that don't relate to a specific model, you can use headless policies:

```crystal
# Define a headless policy
class DashboardPolicy < ApplicationPolicy(Nil)
  def show?
    user != nil  # Only logged-in users can see dashboard
  end
end

# Use in action
class Dashboard::Show < BrowserAction
  get "/dashboard" do
    authorize(:dashboard)  # Uses DashboardPolicy
    
    html DashboardPage
  end
end
```

### Namespaced Policies

For organizing policies under namespaces (e.g., admin policies):

```crystal
module Admin
  class BookPolicy < ApplicationPolicy(Book)
    def update?
      user.try(&.admin?)
    end
  end
end

# Use in action
class Admin::Books::Update < BrowserAction
  post "/admin/books/:book_id" do
    book = BookQuery.find(book_id)
    authorize(object: book, policy: Admin::BookPolicy)
    
    # ... update logic
  end
end
```

### Permitted Attributes

Control which attributes users can modify:

```crystal
class Books::Create < BrowserAction
  post "/books" do
    authorize
    
    # Get permitted attributes based on user permissions
    book = Book.new
    allowed_attrs = permitted_attributes(book)
    
    # Use with your operations, filtering params to only allowed attributes
    SaveBook.create(params.select(allowed_attrs)) do |operation, book|
      # ...
    end
  end
end
```

### Ensuring Authorization

Add verification hooks to ensure all actions are authorized:

```crystal
abstract class BrowserAction < Lucky::Action
  include Pundit::ActionHelpers(User)
  
  after verify_authorized
  after verify_policy_scoped  # If you want to ensure scopes are used
  
  # Skip verification for specific actions
  def index
    skip_authorization  # Skip verify_authorized check
    skip_policy_scope   # Skip verify_policy_scoped check
    
    html PublicPage
  end
end
```

### Authorizing views

Say we have a button to create a new book:

```crystal
def render
  button "Create new book"
end
```

To ensure that the `current_user` is permitted to create a new book before showing the button, we can wrap the button in a policy check:

```crystal
def render
  if BookPolicy.new(current_user).create?
    button "Create new book"
  end
end
```

### View Helpers

For Lucky pages, include the `Pundit::PageHelpers` module to get convenient helper methods:

```crystal
# In your MainLayout or specific pages
include Pundit::PageHelpers

def render
  # Using can? helper
  if can?(edit?, book)
    link "Edit", to: Books::Edit.with(book.id)
  end
  
  # Using cannot? helper
  if cannot?(delete?, book)
    text "You cannot delete this book"
  end
  
  # Using show_if_authorized
  show_if_authorized(update?, book) do
    link "Update", to: Books::Update.with(book.id)
  end
  
  # Getting a policy instance
  book_policy = policy(book)
  if book_policy.publish?
    button "Publish"
  end
end
```

### Policy Helpers in Actions

Additional helper methods are available in actions:

```crystal
class Books::Show < BrowserAction
  get "/books/:book_id" do
    book = BookQuery.find(book_id)
    
    # Get policy instance
    book_policy = policy(book)
    
    # Or enforce policy exists
    book_policy = policy!(book)  # Raises if policy not found
    
    # Custom user object
    def pundit_user
      current_account  # Use custom method instead of current_user
    end
    
    html ShowPage, book: book, policy: book_policy
  end
end
```

### Overriding the User model

If your application doesn't return an instance of `User` from your `current_user` method, you'll need to make the following updates (we're using `Account` as an example):

- Run `lucky pundit.init --user-model {Account}`, or modify your `ApplicationPolicy`'s `initialize` content like this:

  ```crystal
  abstract class ApplicationPolicy(T)
    getter account
    getter record

    def initialize(@account : Account?, @record : T? = nil)
    end
  end
  ```

- Update the `include` of the `Pundit::ActionHelpers` module in `BrowserAction`:

  ```crystal
  # src/actions/browser_action.cr
  include Pundit::ActionHelpers(Account)
  ```

### Testing Policies

Pundit provides test helpers to make policy testing easier:

```crystal
require "spec"
require "pundit/spec_helpers"

include Pundit::SpecHelpers

describe BookPolicy do
  it "allows admin to update any book" do
    admin = User.new(admin: true)
    book = Book.new
    
    assert_permit(BookPolicy, admin, book, update?)
  end
  
  it "prevents regular users from deleting books" do
    user = User.new(admin: false)
    book = Book.new
    
    assert_forbid(BookPolicy, user, book, delete?)
  end
  
  # Using the test macros
  describe_policy(BookPolicy) do
    let(:admin) { User.new(admin: true) }
    let(:user) { User.new(admin: false) }
    let(:book) { Book.new }
    
    it "allows admins all actions" do
      policy = policy_for(admin, book)
      
      policy.update?.should be_true
      policy.delete?.should be_true
    end
  end
  
  # Test permitted attributes
  it "limits attributes for regular users" do
    user = User.new(admin: false)
    policy = BookPolicy.new(user, Book.new)
    
    policy.permitted_attributes.should eq([:title, :body])
  end
end
```

### Handling authorization errors

If a call to `authorize` fails, a `Pundit::NotAuthorizedError` will be raised.

You can handle this elegantly by adding an overloaded `render` method to your `src/actions/errors/show.cr` action:

```crystal
# This class handles error responses and reporting.
#
# https://luckyframework.org/guides/http-and-routing/error-handling
class Errors::Show < Lucky::ErrorAction
  DEFAULT_MESSAGE = "Something went wrong."
  default_format :html

  # Capture Pundit authorization exceptions to handle it elegantly
  def render(error : Pundit::NotAuthorizedError)
    if html?
      # We might want to throw an appropriate status and message
      error_html "Sorry, you're not authorized to access that", status: 401

      # Or maybe we just redirect users back to the previous page
      # redirect_back fallback: Home::Index
    else
      error_json "Not authorized", status: 401
    end
  end
end
```

The error object includes additional context when available:
- `error.policy` - The policy class that was checked
- `error.query` - The method that was called (e.g., "update?")
- `error.record` - The record that was being authorized

## Contributing

1. Fork it (<https://github.com/stephendolan/pundit/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Stephen Dolan](https://github.com/stephendolan) - creator and maintainer

## Inspiration

- The [Pundit](https://github.com/varvet/pundit) Ruby gem was what formed my need as a programmer for this kind of simple approach to authorization
- The [Praetorian](https://github.com/ilanusse/praetorian) Crystal shard took an excellent first step towards proving out the Pundit model in Crystal
