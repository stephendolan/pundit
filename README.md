# Pundit

![Shard CI](https://github.com/stephendolan/pundit/workflows/Shard%20CI/badge.svg)
[![API Documentation Website](https://img.shields.io/website?down_color=red&down_message=Offline&label=API%20Documentation&up_message=Online&url=https%3A%2F%2Fstephendolan.github.io%2Fpundit%2F)](https://stephendolan.github.io/pundit)
[![GitHub release](https://img.shields.io/github/release/stephendolan/pundit.svg?label=Release)](https://github.com/stephendolan/pundit/releases)

A simple Crystal shard for managing authorization in [Lucky](https://luckyframework.org) applications. Intended to mimic the excellent Ruby [Pundit](https://github.com/varvet/pundit) gem.

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

## Usage in Lucky

### Creating policies

TODO: Document what a policy is, and how to create a new one using the built-in tasks (TBD)

### Authorizing actions

Let's say we have a `Books::Index` action that looks like this:

```crystal
class Books::Index < BrowserAction
  get "/books/index" do
    html IndexPage, books: BooksQuery.new
  end
end
```

To use Pundit for authorization, simply add an `authorize` call:

```crystal
class Books::Index < BrowserAction
  get "/books/index" do
    authorize

    html IndexPage, books: BooksQuery.new
  end
end
```

Behind the scenes, this is using the action's class name to check whether the `BooksPolicy`'s `index?` method is permitted for `current_user`. If the call fails, a `Pundit::NotAuthorizedError` is raised with a `401` HTTP status.

The `authorize` call above is identical to writing this:

```crystal
BooksPolicy.new(current_user).index? || raise Pundit::NotAuthorizedError.new
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
  if BooksPolicy.new(current_user).create?
    button "Create new book"
  end
end
```

### Overriding defaults

TODO: Need to document a Lucky task or something to generate the default ApplicationPolicy, and explain how to override

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
