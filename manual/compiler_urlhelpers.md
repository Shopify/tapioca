## UrlHelpers

`Tapioca::Dsl::Compilers::UrlHelpers` generates RBI files for classes that include or extend
[`Rails.application.routes.url_helpers`](https://api.rubyonrails.org/classes/ActionDispatch/Routing/UrlFor.html#module-ActionDispatch::Routing::UrlFor-label-URL+generation+for+named+routes).

The compiler registers generated constants to represent the Rails route helper modules:

1. `GeneratedPathHelpersModule` holds the main application's path helpers, such as `post_path`.

2. `GeneratedUrlHelpersModule` holds the main application's URL helpers, such as `post_url`.

3. `GeneratedMountedHelpers` is a synthetic module for mounted application and engine helpers, such as
`main_app` and `articles`. Rails exposes these helpers through an anonymous dynamic module, so the compiler creates
a named RBI module that can be included or extended by classes that receive mounted helpers at runtime. It is
only generated for applications that mount an engine that defines its own routes.

For mounted engines, the compiler also registers engine-scoped `GeneratedPathHelpersModule` and
`GeneratedUrlHelpersModule` constants. Mounted engine helper methods return a synthetic
`GeneratedRoutesProxy` subclass that includes those engine-scoped helper modules.

For example, with the following setup:

~~~rb
# config/application.rb
class Application < Rails::Application
  routes.draw do
    resource :index

    mount Blog::Engine, at: "/blog", as: "articles"
  end
end
~~~

~~~rb
app/models/post.rb
class Post
  # Use `T.unsafe` so that Sorbet does not complain about a dynamic
  # module being included. This allows the `include` to happen properly
  # at runtime but Sorbet won't see the include. However, since this
  # compiler will generate the proper RBI files for the include,
  # static type checking will work as expected.
  T.unsafe(self).include Rails.application.routes.url_helpers
end
~~~

this compiler will produce the following RBI files:

~~~rbi
# generated_path_helpers_module.rbi
# typed: true
module GeneratedPathHelpersModule
  include ActionDispatch::Routing::PolymorphicRoutes
  include ActionDispatch::Routing::UrlFor

  sig { params(args: T.untyped).returns(String) }
  def articles_path(*args); end

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
  def articles_url(*args); end

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

~~~rb
# blog/config/routes.rb
Blog::Engine.routes.draw do
  resources :posts
end
~~~

~~~rbi
# blog/engine/generated_path_helpers_module.rbi
# typed: true
module Blog::Engine::GeneratedPathHelpersModule
  include ActionDispatch::Routing::PolymorphicRoutes
  include ActionDispatch::Routing::UrlFor

  sig { params(args: T.untyped).returns(String) }
  def edit_post_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_post_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def post_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def posts_path(*args); end
end
~~~

~~~rbi
# blog/engine/generated_url_helpers_module.rbi
# typed: true
module Blog::Engine::GeneratedUrlHelpersModule
  include ActionDispatch::Routing::PolymorphicRoutes
  include ActionDispatch::Routing::UrlFor

  sig { params(args: T.untyped).returns(String) }
  def edit_post_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_post_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def post_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def posts_url(*args); end
end
~~~

~~~rbi
# generated_mounted_helpers.rbi
# typed: true
module GeneratedMountedHelpers
  sig { returns(Blog::Engine::GeneratedRoutesProxy) }
  def articles; end

  sig { returns(GeneratedRoutesProxy) }
  def main_app; end
end
~~~

~~~rbi
# generated_routes_proxy.rbi
# typed: true
class GeneratedRoutesProxy < ::ActionDispatch::Routing::RoutesProxy
  include GeneratedPathHelpersModule
  include GeneratedUrlHelpersModule
end
~~~

~~~rbi
# blog/engine/generated_routes_proxy.rbi
# typed: true
class Blog::Engine::GeneratedRoutesProxy < ::ActionDispatch::Routing::RoutesProxy
  include Blog::Engine::GeneratedPathHelpersModule
  include Blog::Engine::GeneratedUrlHelpersModule
end
~~~
