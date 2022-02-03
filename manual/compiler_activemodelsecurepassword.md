## ActiveModelSecurePassword

`Tapioca::Dsl::Compilers::ActiveModelSecurePassword` decorates RBI files for all
classes that use [`ActiveModel::SecurePassword`](http://api.rubyonrails.org/classes/ActiveModel/SecurePassword/ClassMethods.html).

For example, with the following class:

~~~rb
class User
  include ActiveModel::SecurePassword

  has_secure_password
  has_secure_password :token
end
~~~

this compiler will produce an RBI file with the following content:
~~~rbi
# typed: true

class User
  sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
  def authenticate(unencrypted_password); end

  sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
  def authenticate_password(unencrypted_password); end

  sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
  def authenticate_token(unencrypted_password); end

  sig { returns(T.untyped) }
  def password; end

  sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
  def password=(unencrypted_password); end

  sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
  def password_confirmation=(unencrypted_password); end

  sig { returns(T.untyped) }
  def token; end

  sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
  def token=(unencrypted_password); end

  sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
  def token_confirmation=(unencrypted_password); end
end
~~~
