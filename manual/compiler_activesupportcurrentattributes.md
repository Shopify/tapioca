## ActiveSupportCurrentAttributes

`Tapioca::Dsl::Compilers::ActiveSupportCurrentAttributes` decorates RBI files for all
subclasses of
[`ActiveSupport::CurrentAttributes`](https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html).

For example, with the following singleton class

~~~rb
class Current < ActiveSupport::CurrentAttributes
  extend T::Sig

  attribute :account

  def helper
    # ...
  end

  sig { params(user_id: Integer).void }
  def authenticate(user_id)
    # ...
  end
end
~~~

this compiler will produce an RBI file with the following content:
~~~rbi
# typed: true

class Current
  include GeneratedAttributeMethods

  class << self
    sig { returns(T.untyped) }
    def account; end

    sig { params(account: T.untyped).returns(T.untyped) }
    def account=(account); end

    sig { params(user_id: Integer).void }
    def authenticate(user_id); end

    sig { returns(T.untyped) }
    def helper; end
  end

  module GeneratedAttributeMethods
    sig { returns(T.untyped) }
    def account; end

    sig { params(account: T.untyped).returns(T.untyped) }
    def account=(account); end
  end
end
~~~
