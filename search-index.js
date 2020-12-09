crystal_doc_search_index_callback({"repository_name":"pundit","body":"# Pundit\n\n![Shard CI](https://github.com/stephendolan/pundit/workflows/Shard%20CI/badge.svg)\n[![API Documentation Website](https://img.shields.io/website?down_color=red&down_message=Offline&label=API%20Documentation&up_message=Online&url=https%3A%2F%2Fstephendolan.github.io%2Fpundit%2F)](https://stephendolan.github.io/pundit)\n[![GitHub release](https://img.shields.io/github/release/stephendolan/pundit.svg?label=Release)](https://github.com/stephendolan/pundit/releases)\n\nA simple Crystal shard for managing authorization in [Lucky](https://luckyframework.org) applications. Intended to mimic the excellent Ruby [Pundit](https://github.com/varvet/pundit) gem.\n\n## Lucky Installation\n\n1. Add the dependency to your `shard.yml`:\n\n   ```yaml\n   # shard.yml\n   dependencies:\n     pundit:\n       github: stephendolan/pundit\n   ```\n\n1. Run `shards install`\n\n1. Require the shard in your Lucky application\n\n   ```crystal\n   # shards.cr\n   require \"pundit\"\n   ```\n\n1. Require the tasks in your Lucky application\n\n   ```crystal\n   # tasks.cr\n   require \"pundit/tasks/**\"\n   ```\n\n1. Require a new directory for policy definitions\n\n   ```crystal\n   # app.cr\n   require \"./policies/**\"\n   ```\n\n1. Include the `Pundit::ActionHelpers` module in `BrowserAction`:\n\n   ```crystal\n   # src/actions/browser_action.cr\n   include Pundit::ActionHelpers(User)\n   ```\n\n1. Run the initializer to create your `ApplicationPolicy` if you don't want [the default](src/pundit/application_policy.cr):\n\n   ```sh\n   lucky pundit.init\n   ```\n\n## Usage\n\n### Creating policies\n\nThe easiest way to create new policies is to use the built-in Lucky task! After following the steps in the Installation section, simply run `lucky gen.policy Book`, for example, to create a new `BookPolicy` in your application.\n\nYour policies must inherit from the provided [`ApplicationPolicy(T)`](src/pundit/application_policy.cr) abstract class, where `T` is the model you are authorizing against.\n\nFor example, the `BookPolicy` we created with `lucky gen.policy Book` looks like this:\n\n```crystal\nclass BookPolicy < ApplicationPolicy(Book)\n  def index?\n    false\n  end\n\n  def show?\n    false\n  end\n\n  def create?\n    false\n  end\n\n  def update?\n    false\n  end\n\n  def delete?\n    false\n  end\nend\n```\n\nThe following methods are provided in [`ApplicationPolicy`](src/pundit/application_policy.cr):\n\n| Method Name | Default Value |\n| ----------- | ------------- |\n| `index?`    | `false`       |\n| `show?`     | `false`       |\n| `create?`   | `false`       |\n| `new?`      | `create?`     |\n| `update?`   | `false`       |\n| `edit?`     | `update?`     |\n| `delete?`   | `false`       |\n\n### Authorizing actions\n\nLet's say we have a `Books::Index` action that looks like this:\n\n```crystal\nclass Books::Index < BrowserAction\n  get \"/books/index\" do\n    html IndexPage, books: BookQuery.new\n  end\nend\n```\n\nTo use Pundit for authorization, simply add an `authorize` call:\n\n```crystal\nclass Books::Index < BrowserAction\n  get \"/books/index\" do\n    authorize\n\n    html IndexPage, books: BookQuery.new\n  end\nend\n```\n\nBehind the scenes, this is using the action's class name to check whether the `BookPolicy`'s `index?` method is permitted for `current_user`. If the call fails, a `Pundit::NotAuthorizedError` is raised.\n\nThe `authorize` call above is identical to writing this:\n\n```crystal\nBookPolicy.new(current_user).index? || raise Pundit::NotAuthorizedError.new\n```\n\nYou can also leverage specific records in your authorization. For example, say we have a `Books::Update` action that looks like this:\n\n```crystal\npost \"/books/:book_id/update\" do\n  book = BookQuery.find(book_id)\n\n  SaveBook.update(book, params) do |operation, book|\n    redirect Home::Index\n  end\nend\n```\n\nWe can add an `authorize` call to check whether or not the user is permitted to update this specific book like this:\n\n```crystal\npost \"/books/:book_id/update\" do\n  book = BookQuery.find(book_id)\n\n  authorize(book)\n\n  SaveBook.update(book, params) do |operation, book|\n    redirect Home::Index\n  end\nend\n```\n\n### Authorizing views\n\nSay we have a button to create a new book:\n\n```crystal\ndef render\n  button \"Create new book\"\nend\n```\n\nTo ensure that the `current_user` is permitted to create a new book before showing the button, we can wrap the button in a policy check:\n\n```crystal\ndef render\n  if BookPolicy.new(current_user).create?\n    button \"Create new book\"\n  end\nend\n```\n\n### Overriding the User model\n\nIf your application doesn't return an instance of `User` from your `current_user` method, you'll need to make the following updates (we're using `Account` as an example):\n\n- Run `lucky pundit.init --user-model {Account}`, or modify your `ApplicationPolicy`'s `initialize` content like this:\n\n  ```crystal\n  abstract class ApplicationPolicy(T)\n    getter account\n    getter record\n\n    def initialize(@account : Account?, @record : T? = nil)\n    end\n  end\n  ```\n\n- Update the `include` of the `Pundit::ActionHelpers` module in `BrowserAction`:\n\n  ```crystal\n  # src/actions/browser_action.cr\n  include Pundit::ActionHelpers(Account)\n  ```\n\n### Handling authorization errors\n\nIf a call to `authorize` fails, a `Pundit::NotAuthorizedError` will be raised.\n\nYou can handle this elegantly by adding an overloaded `render` method to your `src/actions/errors/show.cr` action:\n\n```crystal\n# This class handles error responses and reporting.\n#\n# https://luckyframework.org/guides/http-and-routing/error-handling\nclass Errors::Show < Lucky::ErrorAction\n  DEFAULT_MESSAGE = \"Something went wrong.\"\n  default_format :html\n\n  # Capture Pundit authorization exceptions to handle it elegantly\n  def render(error : Pundit::NotAuthorizedError)\n    if html?\n      # We might want to throw an appropriate status and message\n      error_html \"Sorry, you're not authorized to access that\", status: 401\n\n      # Or maybe we just redirect users back to the previous page\n      # redirect_back fallback: Home::Index\n    else\n      error_json \"Not authorized\", status: 401\n    end\n  end\nend\n```\n\n## Contributing\n\n1. Fork it (<https://github.com/stephendolan/pundit/fork>)\n2. Create your feature branch (`git checkout -b my-new-feature`)\n3. Commit your changes (`git commit -am 'Add some feature'`)\n4. Push to the branch (`git push origin my-new-feature`)\n5. Create a new Pull Request\n\n## Contributors\n\n- [Stephen Dolan](https://github.com/stephendolan) - creator and maintainer\n\n## Inspiration\n\n- The [Pundit](https://github.com/varvet/pundit) Ruby gem was what formed my need as a programmer for this kind of simple approach to authorization\n- The [Praetorian](https://github.com/ilanusse/praetorian) Crystal shard took an excellent first step towards proving out the Pundit model in Crystal\n","program":{"html_id":"pundit/toplevel","path":"toplevel.html","kind":"module","full_name":"Top Level Namespace","name":"Top Level Namespace","abstract":false,"superclass":null,"ancestors":[],"locations":[],"repository_name":"pundit","program":true,"enum":false,"alias":false,"aliased":"","const":false,"constants":[],"included_modules":[],"extended_modules":[],"subclasses":[],"including_types":[],"namespace":null,"doc":null,"summary":null,"class_methods":[],"constructors":[],"instance_methods":[],"macros":[],"types":[{"html_id":"pundit/ApplicationPolicy","path":"ApplicationPolicy.html","kind":"class","full_name":"ApplicationPolicy(T)","name":"ApplicationPolicy","abstract":true,"superclass":{"html_id":"pundit/Reference","kind":"class","full_name":"Reference","name":"Reference"},"ancestors":[{"html_id":"pundit/Reference","kind":"class","full_name":"Reference","name":"Reference"},{"html_id":"pundit/Object","kind":"class","full_name":"Object","name":"Object"}],"locations":[{"filename":"src/pundit/application_policy.cr","line_number":4,"url":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/application_policy.cr#L4"}],"repository_name":"pundit","program":false,"enum":false,"alias":false,"aliased":"","const":false,"constants":[],"included_modules":[],"extended_modules":[],"subclasses":[],"including_types":[],"namespace":null,"doc":"The default Pundit policy that all other policies should inherit from.\n\nShould you with to update the default policy definitions, run `lucky pundit.init` and override where needed.","summary":"<p>The default Pundit policy that all other policies should inherit from.</p>","class_methods":[],"constructors":[{"id":"new(user:User?,record:T?=nil)-class-method","html_id":"new(user:User?,record:T?=nil)-class-method","name":"new","doc":"A policy takes in a user that might be nil, as well as an object that may be nil.\n\nThese are available in all policy check methods for access.","summary":"<p>A policy takes in a user that might be nil, as well as an object that may be nil.</p>","abstract":false,"args":[{"name":"user","doc":null,"default_value":"","external_name":"user","restriction":"User | ::Nil"},{"name":"record","doc":null,"default_value":"nil","external_name":"record","restriction":"T | ::Nil"}],"args_string":"(user : User?, record : T? = <span class=\"n\">nil</span>)","source_link":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/application_policy.cr#L11","def":{"name":"new","args":[{"name":"user","doc":null,"default_value":"","external_name":"user","restriction":"User | ::Nil"},{"name":"record","doc":null,"default_value":"nil","external_name":"record","restriction":"T | ::Nil"}],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"","visibility":"Public","body":"_ = ApplicationPolicy(T).allocate\n_.initialize(user, record)\nif _.responds_to?(:finalize)\n  ::GC.add_finalizer(_)\nend\n_\n"}}],"instance_methods":[{"id":"create?-instance-method","html_id":"create?-instance-method","name":"create?","doc":"Whether or not the `Create` action can be accessed","summary":"<p>Whether or not the <code>Create</code> action can be accessed</p>","abstract":false,"args":[],"args_string":"","source_link":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/application_policy.cr#L25","def":{"name":"create?","args":[],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"","visibility":"Public","body":"false"}},{"id":"delete?-instance-method","html_id":"delete?-instance-method","name":"delete?","doc":"Whether or not the `Delete` action can be accessed","summary":"<p>Whether or not the <code>Delete</code> action can be accessed</p>","abstract":false,"args":[],"args_string":"","source_link":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/application_policy.cr#L45","def":{"name":"delete?","args":[],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"","visibility":"Public","body":"false"}},{"id":"edit?-instance-method","html_id":"edit?-instance-method","name":"edit?","doc":"Whether or not the `Edit` action can be accessed","summary":"<p>Whether or not the <code>Edit</code> action can be accessed</p>","abstract":false,"args":[],"args_string":"","source_link":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/application_policy.cr#L40","def":{"name":"edit?","args":[],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"","visibility":"Public","body":"update?"}},{"id":"index?-instance-method","html_id":"index?-instance-method","name":"index?","doc":"Whether or not the `Index` action can be accessed","summary":"<p>Whether or not the <code>Index</code> action can be accessed</p>","abstract":false,"args":[],"args_string":"","source_link":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/application_policy.cr#L15","def":{"name":"index?","args":[],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"","visibility":"Public","body":"false"}},{"id":"new?-instance-method","html_id":"new?-instance-method","name":"new?","doc":"Whether or not the `New` action can be accessed","summary":"<p>Whether or not the <code>New</code> action can be accessed</p>","abstract":false,"args":[],"args_string":"","source_link":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/application_policy.cr#L30","def":{"name":"new?","args":[],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"","visibility":"Public","body":"create?"}},{"id":"record-instance-method","html_id":"record-instance-method","name":"record","doc":null,"summary":null,"abstract":false,"args":[],"args_string":"","source_link":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/application_policy.cr#L6","def":{"name":"record","args":[],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"","visibility":"Public","body":"@record"}},{"id":"show?-instance-method","html_id":"show?-instance-method","name":"show?","doc":"Whether or not the `Show` action can be accessed","summary":"<p>Whether or not the <code>Show</code> action can be accessed</p>","abstract":false,"args":[],"args_string":"","source_link":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/application_policy.cr#L20","def":{"name":"show?","args":[],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"","visibility":"Public","body":"false"}},{"id":"update?-instance-method","html_id":"update?-instance-method","name":"update?","doc":"Whether or not the `Update` action can be accessed","summary":"<p>Whether or not the <code>Update</code> action can be accessed</p>","abstract":false,"args":[],"args_string":"","source_link":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/application_policy.cr#L35","def":{"name":"update?","args":[],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"","visibility":"Public","body":"false"}},{"id":"user-instance-method","html_id":"user-instance-method","name":"user","doc":null,"summary":null,"abstract":false,"args":[],"args_string":"","source_link":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/application_policy.cr#L5","def":{"name":"user","args":[],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"","visibility":"Public","body":"@user"}}],"macros":[],"types":[]},{"html_id":"pundit/Pundit","path":"Pundit.html","kind":"module","full_name":"Pundit","name":"Pundit","abstract":false,"superclass":null,"ancestors":[],"locations":[{"filename":"src/pundit.cr","line_number":4,"url":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit.cr#L4"},{"filename":"src/pundit/action_helpers.cr","line_number":2,"url":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/action_helpers.cr#L2"},{"filename":"src/pundit/not_authorized_error.cr","line_number":1,"url":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/not_authorized_error.cr#L1"},{"filename":"src/pundit/version.cr","line_number":1,"url":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/version.cr#L1"}],"repository_name":"pundit","program":false,"enum":false,"alias":false,"aliased":"","const":false,"constants":[{"id":"VERSION","name":"VERSION","value":"\"0.7.1\"","doc":null,"summary":null}],"included_modules":[],"extended_modules":[],"subclasses":[],"including_types":[],"namespace":null,"doc":"Pundit aims to provide a quick and easy way to check authorization in a Lucky application.","summary":"<p>Pundit aims to provide a quick and easy way to check authorization in a Lucky application.</p>","class_methods":[],"constructors":[],"instance_methods":[],"macros":[],"types":[{"html_id":"pundit/Pundit/ActionHelpers","path":"Pundit/ActionHelpers.html","kind":"module","full_name":"Pundit::ActionHelpers(T)","name":"ActionHelpers","abstract":false,"superclass":null,"ancestors":[],"locations":[{"filename":"src/pundit/action_helpers.cr","line_number":2,"url":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/action_helpers.cr#L2"}],"repository_name":"pundit","program":false,"enum":false,"alias":false,"aliased":"","const":false,"constants":[],"included_modules":[],"extended_modules":[],"subclasses":[],"including_types":[],"namespace":{"html_id":"pundit/Pundit","kind":"module","full_name":"Pundit","name":"Pundit"},"doc":"A set of helpers that can be included in your Lucky `BrowserAction` and made available to all child actions.","summary":"<p>A set of helpers that can be included in your Lucky <code>BrowserAction</code> and made available to all child actions.</p>","class_methods":[],"constructors":[],"instance_methods":[{"id":"current_user:T?-instance-method","html_id":"current_user:T?-instance-method","name":"current_user","doc":"Pundit needs to leverage the `current_user` method for implicit authorization checks","summary":"<p>Pundit needs to leverage the <code><a href=\"../Pundit/ActionHelpers.html#current_user:T?-instance-method\">#current_user</a></code> method for implicit authorization checks</p>","abstract":true,"args":[],"args_string":" : T?","source_link":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/action_helpers.cr#L60","def":{"name":"current_user","args":[],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"T | ::Nil","visibility":"Public","body":""}}],"macros":[{"id":"authorize(object=nil,policy=nil,query=nil)-macro","html_id":"authorize(object=nil,policy=nil,query=nil)-macro","name":"authorize","doc":"The `authorize` method can be added to any action to determine whether or not the `current_user` can take that action.\n\nIn its simplest form, you don't have to provide any parameters:\n\n```\nclass Books::Index < BrowserAction\n  get \"/books\" do\n    authorize\n\n    html Books::IndexPage, books: BooksQuery.new\n  end\nend\n```\n\nThis is equivalent to replacing `authorize` with `BookPolicy.new(current_user).index? || raise Pundit::NotAuthorizedError`","summary":"<p>The <code><a href=\"../Pundit/ActionHelpers.html#authorize(object=nil,policy=nil,query=nil)-macro\">authorize</a></code> method can be added to any action to determine whether or not the <code><a href=\"../Pundit/ActionHelpers.html#current_user:T?-instance-method\">#current_user</a></code> can take that action.</p>","abstract":false,"args":[{"name":"object","doc":null,"default_value":"nil","external_name":"object","restriction":""},{"name":"policy","doc":null,"default_value":"nil","external_name":"policy","restriction":""},{"name":"query","doc":null,"default_value":"nil","external_name":"query","restriction":""}],"args_string":"(object = <span class=\"n\">nil</span>, policy = <span class=\"n\">nil</span>, query = <span class=\"n\">nil</span>)","source_link":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/action_helpers.cr#L18","def":{"name":"authorize","args":[{"name":"object","doc":null,"default_value":"nil","external_name":"object","restriction":""},{"name":"policy","doc":null,"default_value":"nil","external_name":"policy","restriction":""},{"name":"query","doc":null,"default_value":"nil","external_name":"query","restriction":""}],"double_splat":null,"splat_index":null,"block_arg":null,"visibility":"Public","body":"    \n# Split up the calling class to make it easier to work with\n\n    \n{% caller_class_array = @type.stringify.split(\"::\") %}\n\n\n    \n# First, get the plural base class.\n\n    \n# For `Store::Books::Index`, this yields `Store::Books`\n\n    \n{% caller_class_base_plural = caller_class_array[0..-2].join(\"::\") %}\n\n\n    \n# Next, singularize that base class.\n\n    \n# For `Store::Books`, this yields `Store::Book`\n\n    \n{% caller_class_base_singular = run(\"./run_macros/singularize.cr\", caller_class_base_plural) %}\n\n\n    \n# Finally, turn that base class into a policy.\n\n    \n# For `Store::Book`, this yields `Store::BookPolicy`.\n\n    \n# Accepts an override if a policy class has been manually provied\n\n    policy_class = \n{% if policy %}\n      {{ policy }}\n    {% else %}\n      {{ caller_class_base_singular.id }}Policy\n    {% end %}\n\n\n    \n# Pluck the action from the calling class and turn it into a policy method.\n\n    \n# For `Store::Books::Index`, this yields `index?`\n\n    \n{% method_name = (caller_class_array.last.underscore + \"?\").id %}\n\n\n    \n# Accept the override if a policy method has been manually provied\n\n    \n{% if query %}\n      {% method_name = query.id %}\n    {% end %}\n\n\n    \n# Finally, call the policy method.\n\n    \n# For `authorize` within `Store::Books::Index`, this calls `Store::BookPolicy.new(current_user, nil).index?`\n\n    is_authorized = policy_class.new(current_user, \n{{ object }}\n).\n{{ method_name }}\n\n\n    if is_authorized\n      \n{{ object }}\n || is_authorized\n    \nelse\n      raise Pundit::NotAuthorizedError.new\n    \nend\n  \n"}}],"types":[]},{"html_id":"pundit/Pundit/NotAuthorizedError","path":"Pundit/NotAuthorizedError.html","kind":"class","full_name":"Pundit::NotAuthorizedError","name":"NotAuthorizedError","abstract":false,"superclass":{"html_id":"pundit/Exception","kind":"class","full_name":"Exception","name":"Exception"},"ancestors":[{"html_id":"pundit/Exception","kind":"class","full_name":"Exception","name":"Exception"},{"html_id":"pundit/Reference","kind":"class","full_name":"Reference","name":"Reference"},{"html_id":"pundit/Object","kind":"class","full_name":"Object","name":"Object"}],"locations":[{"filename":"src/pundit/not_authorized_error.cr","line_number":3,"url":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/not_authorized_error.cr#L3"}],"repository_name":"pundit","program":false,"enum":false,"alias":false,"aliased":"","const":false,"constants":[],"included_modules":[],"extended_modules":[],"subclasses":[],"including_types":[],"namespace":{"html_id":"pundit/Pundit","kind":"module","full_name":"Pundit","name":"Pundit"},"doc":"The exception that is raised when authorization fails for a policy check","summary":"<p>The exception that is raised when authorization fails for a policy check</p>","class_methods":[],"constructors":[{"id":"new-class-method","html_id":"new-class-method","name":"new","doc":null,"summary":null,"abstract":false,"args":[],"args_string":"","source_link":"https://github.com/stephendolan/pundit/blob/ca836b747bbb466204ab41f288675accd67d92b0/src/pundit/not_authorized_error.cr#L4","def":{"name":"new","args":[],"double_splat":null,"splat_index":null,"yields":null,"block_arg":null,"return_type":"","visibility":"Public","body":"_ = allocate\n_.initialize\nif _.responds_to?(:finalize)\n  ::GC.add_finalizer(_)\nend\n_\n"}}],"instance_methods":[],"macros":[],"types":[]}]}]}})