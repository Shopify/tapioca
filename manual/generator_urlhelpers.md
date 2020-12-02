## UrlHelpers

`Tapioca::Compilers::Dsl::UrlHelpers` generates RBI files for classes that include or extend
[`Rails.application.routes.url_helpers`](https://api.rubyonrails.org/v5.1.7/classes/ActionDispatch/Routing/UrlFor.html#module-ActionDispatch::Routing::UrlFor-label-URL+generation+for+named+routes).

For example, with the following setup:

~~~rb
# config/application.rb
class Application < Rails::Application
  routes.draw do
    resource :index
  end
end
~~~

~~~rb
app/models/post.rb
class Post
  # Use `T.unsafe` so that Sorbet does not complain about a dynamic
  # module being included. This allows the `include` to happen properly
  # at runtime but Sorbet won't see the include. However, since this
  # generator will generate the proper RBI files for the include,
  # type-checking will work as expected.
  T.unsafe(self).include Rails.application.routes.url_helpers
end
~~~

this generator will produce the following RBI files:

~~~rbi
# generated_path_helpers_module.rbi
# typed: true
module GeneratedPathHelpersModule
  include ActionDispatch::Routing::PolymorphicRoutes
  include ActionDispatch::Routing::UrlFor

  sig { params(args: T.untyped).returns(String) }
  def edit_index_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def index_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_index_path(*args); end
end
~~~

~~~rbi
# generated_url_helpers_module.rbi
# typed: true
module GeneratedUrlHelpersModule
  include ActionDispatch::Routing::PolymorphicRoutes
  include ActionDispatch::Routing::UrlFor

  sig { params(args: T.untyped).returns(String) }
  def edit_index_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def index_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_index_url(*args); end
end
~~~

~~~rbi
# post.rbi
# typed: true
class Post
  include GeneratedPathHelpersModule
  include GeneratedUrlHelpersModule
end
~~~
