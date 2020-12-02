# Pundit

![Shard CI](https://github.com/stephendolan/pundit/workflows/Shard%20CI/badge.svg)
[![API Documentation Website](https://img.shields.io/website?down_color=red&down_message=Offline&label=API%20Documentation&up_message=Online&url=https%3A%2F%2Fstephendolan.github.io%2Fpundit%2F)](https://stephendolan.github.io/pundit)
[![GitHub release](https://img.shields.io/github/release/stephendolan/pundit.svg?label=Release)](https://github.com/stephendolan/pundit/releases)

A simple Crystal shard for managing authorization in [Lucky](https://luckyframework.org) applications. Intended to mimic the excellent Ruby [Pundit](https://github.com/varvet/pundit) gem.

**This library should not be used in production, as it is still actively undergoing API changes and is largely untested**

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

## Usage

### Creating policies

Your policies must inherit from the provided [`ApplicationPolicy(T)`](src/pundit/application_policy.cr) abstract class, where `T` is the model you are authorizing against.

For example, a `BookPolicy` may look like this:

```crystal
class BookPolicy < ApplicationPolicy(Book)
  def index?
    true
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

### Overriding defaults

TODO: Need to document a Lucky task or something to generate the default ApplicationPolicy, and explain how to override

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
