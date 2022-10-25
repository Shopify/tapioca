## ActiveRecordDelegatedTypes

`Tapioca::Dsl::Compilers::DelegatedTypes` defines RBI files for subclasses of
[`ActiveRecord::Base`](https://api.rubyonrails.org/classes/ActiveRecord/Base.html).
This compiler is only responsible for defining the methods that would be created for delegated_types that
are defined in the Active Record model.

For example, with the following model class:

~~~rb
class Entry < ActiveRecord::Base
  delegated_type :entryable, types: %w[ Message Comment ]
end
~~~

this compiler will produce the following methods in the RBI file
`entry.rbi`:

~~~rbi
# entry.rbi
# typed: true

class Entry
  include GeneratedDelegatedTypeMethods

  module GeneratedDelegatedTypeMethods
    sig { params(args: T.untyped).returns(T.any(Message, Comment)) }
    def build_entryable(*args); end

    sig { returns(Class) }
    def entryable_class; end

    sig { returns(String) }
    def entryable_name; end

    sig { returns(T::Boolean) }
    def message?; end

    sig { returns(T.nilable(Message)) }
    def message; end

    sig { returns(T.nilable(Integer)) }
    def message_id; end

    sig { returns(T::Boolean) }
    def comment?; end

    sig { returns(T.nilable(Comment)) }
    def comment; end

    sig { returns(T.nilable(Integer)) }
    def comment_id; end
  end
end

~~~
