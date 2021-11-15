## ActionViewTestHelpers

`Tapioca::Compilers::Dsl::ActionViewTestHelpers` decorates RBI files for all
subclasses of `ActionView::TestCase` with the helpers that are included dynamically.

For example, considering the `UsersHelper` module:

~~~rb
module UsersHelper
  def current_user_name
    # ...
  end
end
~~~

and its respective test:

~~~rb
class UsersHelperTest < ActionView::TestCase
  test "current_user_name works" do
    assert_equal("John", current_user_name)
  end
end
~~~

this generator will produce an RBI file `users_helper_test.rbi` with the following content:

~~~rbi
# users_helper_test.rbi
# typed: strong
class UsersHelperTest
  include HelperMethods

  module HelperMethods
    include ::UsersHelper
  end
end
~~~
