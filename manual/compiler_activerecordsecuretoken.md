## ActiveRecordSecureToken

`Tapioca::Dsl::Compilers::ActiveModelSecurePassword` decorates RBI files for all
classes that use [`ActiveRecord::SecureToken`](https://api.rubyonrails.org/classes/ActiveRecord/SecureToken/ClassMethods.html).

For example, with the following class:

~~~rb
class User < ActiveRecord::Base
  has_secure_token
  has_secure_token :auth_token, length: 36
end
~~~

this compiler will produce an RBI file with the following content:
~~~rbi
# typed: true

class User
  sig { returns(T::Boolean) }
  def regenerate_token; end

  sig { returns(T::Boolean) }
  def regenerate_auth_token; end
end
~~~
