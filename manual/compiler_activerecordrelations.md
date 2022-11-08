## ActiveRecordRelations

`Tapioca::Dsl::Compilers::ActiveRecordRelations` decorates RBI files for subclasses of
`ActiveRecord::Base` and adds
[relation](http://api.rubyonrails.org/classes/ActiveRecord/Relation.html),
[collection proxy](https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html),
[query](http://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html),
[spawn](http://api.rubyonrails.org/classes/ActiveRecord/SpawnMethods.html),
[finder](http://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html), and
[calculation](http://api.rubyonrails.org/classes/ActiveRecord/Calculations.html) methods.

The compiler defines 3 (synthetic) modules and 3 (synthetic) classes to represent relations properly.

For a given model `Model`, we generate the following classes:

1. A `Model::PrivateRelation` that subclasses `ActiveRecord::Relation`. This synthetic class represents
a relation on `Model` whose methods which return a relation always return a `Model::PrivateRelation` instance.

2. `Model::PrivateAssocationRelation` that subclasses `ActiveRecord::AssociationRelation`. This synthetic
class represents a relation on a singular association of type `Model` (e.g. `foo.model`) whose methods which
return a relation will always return a `Model::PrivateAssocationRelation` instance. The difference between this
class and the previous one is mainly that an association relation also keeps track of the resource association
for this relation.

3. `Model::PrivateCollectionProxy` that subclasses from `ActiveRecord::Associations::CollectionProxy`.
This synthetic class represents a relation on a plural association of type `Model` (e.g. `foo.models`)
whose methods which return a relation will always return a `Model::PrivateAssocationRelation` instance.
This class represents a collection of `Model` instances with some extra methods to `build`, `create`,
etc new `Model` instances in the collection.

and the following modules:

1. `Model::GeneratedRelationMethods` holds all the relation methods with the return type of
`Model::PrivateRelation`. For example, calling `all` on the `Model` class or an instance of
`Model::PrivateRelation` class will always return a `Model::PrivateRelation` instance, thus the
signature of `all` is defined with that return type in this module.

2. `Model::GeneratedAssociationRelationMethods` holds all the relation methods with the return type
of `Model::PrivateAssociationRelation`. For example, calling `all` on an instance of
`Model::PrivateAssociationRelation` or an instance of `Model::PrivateCollectionProxy` class will
always return a `Model::PrivateAssociationRelation` instance, thus the signature of `all` is defined
with that return type in this module.

3. `Model::CommonRelationMethods` holds all the relation methods that do not depend on the type of
relation in their return type. For example, `find_by!` will always return the same type (a `Model`
instance), regardless of what kind of relation it is called on, and so belongs in this module.
This module is used to reduce the replication of methods between the previous two modules.

Additionally, the actual `Model` class extends both `Model::CommonRelationMethods` and
`Model::PrivateRelation` modules, so that, for example, `find_by` and `all` can be chained off of the
`Model` class.

**A note on find**: `find` is typed as `T.untyped` by default.

While it is often used in the manner of `Model.find(id)`, Rails does support pasing in an array to find, which
would then return a `T::Enumerable[Model]`. This would force a static cast everywhere find is used to avoid type
errors. This is not ideal considering very few users of find use the array syntax over a where. With untyped,
this cast is optional and so it was decided to avoid typing it. If you need runtime guarentees when using `find`
the best method of doing so is by casting the return value to the model: `T.cast(Model.find(id), Model)`.
`find_by` does guarentee a return value of `Model`, so find can can be refactored accordingly:
`Model.find_by!(id: id)`. This will avoid the cast requirement at runtime.

**CAUTION**: The generated relation classes are named `PrivateXXX` intentionally to reflect the fact
that they represent private subconstants of the Active Record model. As such, these types do not
exist at runtime, and their counterparts that do exist at runtime are marked `private_constant` anyway.
For that reason, these types cannot be used in user code or in `sig`s inside Ruby files, since that will
make the runtime checks fail.

For example, with the following `ActiveRecord::Base` subclass:

~~~rb
class Post < ApplicationRecord
end
~~~

this compiler will produce the RBI file `post.rbi` with the following content:
~~~rbi
# post.rbi
# typed: true

class Post
  extend CommonRelationMethods
  extend GeneratedRelationMethods

  module CommonRelationMethods
    sig { params(block: T.nilable(T.proc.params(record: ::Post).returns(T.untyped))).returns(T::Boolean) }
    def any?(&block); end

    # ...
  end

  module GeneratedAssociationRelationMethods
    sig { returns(PrivateAssociationRelation) }
    def all; end

    # ...

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def where(*args, &blk); end
  end

  module GeneratedRelationMethods
    sig { returns(PrivateRelation) }
    def all; end

    # ...

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def where(*args, &blk); end
  end

  class PrivateAssociationRelation < ::ActiveRecord::AssociationRelation
    include CommonRelationMethods
    include GeneratedAssociationRelationMethods

    sig { returns(T::Array[::Post]) }
    def to_ary; end

    Elem = type_member { { fixed: ::Post } }
  end

  class PrivateCollectionProxy < ::ActiveRecord::Associations::CollectionProxy
    include CommonRelationMethods
    include GeneratedAssociationRelationMethods

    sig do
      params(records: T.any(::Post, T::Array[::Post], T::Array[PrivateCollectionProxy]))
        .returns(PrivateCollectionProxy)
    end
    def <<(*records); end

    # ...
  end

  class PrivateRelation < ::ActiveRecord::Relation
    include CommonRelationMethods
    include GeneratedRelationMethods

    sig { returns(T::Array[::Post]) }
    def to_ary; end

    Elem = type_member { { fixed: ::Post } }
  end
end
~~~

**A note about migrating from `sorbet-rails`**: there is no direct analogue to `Post::RelationType` in Tapioca.  

`sorbet-rails` actually [changes the way a Rails application loads](https://github.com/chanzuckerberg/sorbet-rails/blob/447ecbe4a2586ce8aa9055290d571fe34a55e27f/lib/sorbet-rails/railtie.rb#L26-L50) in order to make `RelationType` work at runtime.  One strategy to add types for relations is to use `WithoutRuntime`.  For example:

~~~rbi
T::Sig::WithoutRuntime.sig { returns(Post::PrivateRelation) }
def posts
  Post.where(id: 123)
end
~~~

As the name suggests, this will give you type checking during development but disable it at runtime.
