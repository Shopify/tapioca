## FrozenRecord

`Tapioca::Compilers::Dsl::FrozenRecord` generates RBI files for subclasses of
[`FrozenRecord::Base`](https://github.com/byroot/frozen_record).

For example, with the following FrozenRecord class:

~~~rb
# student.rb
class Student < FrozenRecord::Base
end
~~~

and the following YAML file:

~~~ yaml
# students.yml
- id: 1
  first_name: John
  last_name: Smith
- id: 2
  first_name: Dan
  last_name:  Lord
~~~

this compiler will produce the RBI file `student.rbi` with the following content:

~~~rbi
# Student.rbi
# typed: strong
class Student
  include FrozenRecordAttributeMethods

  module FrozenRecordAttributeMethods
    sig { returns(T.untyped) }
    def first_name; end

    sig { returns(T::Boolean) }
    def first_name?; end

    sig { returns(T.untyped) }
    def id; end

    sig { returns(T::Boolean) }
    def id?; end

    sig { returns(T.untyped) }
    def last_name; end

    sig { returns(T::Boolean) }
    def last_name?; end
  end
end
~~~
