## ControllerActions

`Tapioca::Dsl::Compilers::ControllerActions` generates RBI files for classes that include
[`ActionController::Base`](https://api.rubyonrails.org/classes/ActionController/Base.html).

For example, with the following class that includes `ActionController::Base`:

~~~rb
class PostsController < ApplicationController
 def index
  # ...
 end

 def create
   # ...
 end
end
~~~

this compiler will produce the RBI file `posts_controller.rbi` with the following content:

~~~rbi
# posts_controller.rbi
# typed: strong
class PostsController
  sig { void }
  def index; end

  sig { void }
  def create; end
end
~~~
