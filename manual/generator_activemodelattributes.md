## ActiveModelAttributes

`Tapioca::Compilers::Dsl::ActiveModelAttributes` decorates RBI files for all
classes that use [`ActiveModel::Attributes`](https://edgeapi.rubyonrails.org/classes/ActiveModel/Attributes/ClassMethods.html).

For example, with the following class:

~~~rb
class Shop
  include ActiveModel::Attributes

  attribute :name, :string
end
~~~

this generator will produce an RBI file with the following content:
~~~rbi
# typed: true

class Shop

  sig { returns(::String) }
  def name; end

  sig { params(name: ::String).returns(::String) }
  def name=(name); end
end
~~~
