## ActionControllerHelpers

`Tapioca::Compilers::Dsl::ActionControllerHelpers` decorates RBI files for all
subclasses of `::ActionController::Base`
to add helper methods (see https://api.rubyonrails.org/classes/ActionController/Helpers.html).

For example, with the following `MyHelper` module:

~~~rb
module MyHelper
  def greet(user)
    # ...
  end

 def localized_time
    # ...
  end
end
~~~

and the following controller:

~~~rb
class UserController < ActionController::Base
  helper MyHelper
  helper { def age(user) "99" end }
  helper_method :current_user_name

  def current_user_name
    # ...
  end
end
~~~

this generator will produce an RBI file `user_controller.rbi` with the following content:

~~~rbi
# user_controller.rbi
# typed: strong
class UserController
  sig { returns(UserController::HelperProxy) }
  def helpers; end
end

module UserController::HelperMethods
   include MyHelper

   sig { params(user: T.untyped).returns(T.untyped) }
   def age(user); end

   sig { returns(T.untyped) }
   def current_user_name; end
 end

class UserController::HelperProxy < ::ActionView::Base
  include UserController::HelperMethods
end
~~~
