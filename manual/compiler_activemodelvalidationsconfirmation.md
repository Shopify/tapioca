## ActiveModelValidationsConfirmation

`Tapioca::Dsl::Compilers::ActiveModelValidationsConfirmation` decorates RBI files for all
classes that use [`ActiveModel::Validates::Confirmation`](https://api.rubyonrails.org/classes/ActiveModel/Validations/HelperMethods.html#method-i-validates_confirmation_of).

For example, with the following class:

~~~rb
class User
  include ActiveModel::Validations

  validates_confirmation_of :password

  validates :email, confirmation: true
end
~~~

this compiler will produce an RBI file with the following content:
~~~rbi
# typed: true

class User

  sig { returns(T.untyped) }
  def email_confirmation; end

  sig { params(email_confirmation=: T.untyped).returns(T.untyped) }
  def email_confirmation=(email_confirmation); end

  sig { returns(T.untyped) }
  def password_confirmation; end

  sig { params(password_confirmation=: T.untyped).returns(T.untyped) }
  def password_confirmation=(password_confirmation); end
end
~~~
