## ActiveSupportConcern

`Tapioca::Compilers::Dsl::ActiveSupportConcern` generates RBI files for classes that both `extend`
`ActiveSupport::Concern` and `include` another class that extends `ActiveSupport::Concern`

For example for the following hierarchy:

~~~rb
# concern.rb
module Foo
 extend ActiveSupport::Concern
 module ClassMethods; end
end

module Bar
 extend ActiveSupport::Concern
 module ClassMethods; end
 include Foo
end

class Baz
 include Bar
end
~~~

this generator will produce the RBI file `concern.rbi` with the following content:

~~~rbi
# typed: true
module Bar
  mixes_in_class_methods(::Foo::ClassMethods)
end
~~~
