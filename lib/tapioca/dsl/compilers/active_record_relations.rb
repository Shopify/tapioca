# typed: strict
# frozen_string_literal: true

begin
  require "active_record"
rescue LoadError
  return
end

require "tapioca/dsl/helpers/active_record_constants_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveRecordRelations` decorates RBI files for subclasses of
      # `ActiveRecord::Base` and adds
      # [relation](http://api.rubyonrails.org/classes/ActiveRecord/Relation.html),
      # [collection proxy](https://api.rubyonrails.org/classes/ActiveRecord/Associations/CollectionProxy.html),
      # [query](http://api.rubyonrails.org/classes/ActiveRecord/QueryMethods.html),
      # [spawn](http://api.rubyonrails.org/classes/ActiveRecord/SpawnMethods.html),
      # [finder](http://api.rubyonrails.org/classes/ActiveRecord/FinderMethods.html), and
      # [calculation](http://api.rubyonrails.org/classes/ActiveRecord/Calculations.html) methods.
      #
      # The compiler defines 3 (synthetic) modules and 3 (synthetic) classes to represent relations properly.
      #
      # For a given model `Model`, we generate the following classes:
      #
      # 1. A `Model::PrivateRelation` that subclasses `ActiveRecord::Relation`. This synthetic class represents
      # a relation on `Model` whose methods which return a relation always return a `Model::PrivateRelation` instance.
      #
      # 2. `Model::PrivateAssocationRelation` that subclasses `ActiveRecord::AssociationRelation`. This synthetic
      # class represents a relation on a singular association of type `Model` (e.g. `foo.model`) whose methods which
      # return a relation will always return a `Model::PrivateAssocationRelation` instance. The difference between this
      # class and the previous one is mainly that an association relation also keeps track of the resource association
      # for this relation.
      #
      # 3. `Model::PrivateCollectionProxy` that subclasses from `ActiveRecord::Associations::CollectionProxy`.
      # This synthetic class represents a relation on a plural association of type `Model` (e.g. `foo.models`)
      # whose methods which return a relation will always return a `Model::PrivateAssocationRelation` instance.
      # This class represents a collection of `Model` instances with some extra methods to `build`, `create`,
      # etc new `Model` instances in the collection.
      #
      # and the following modules:
      #
      # 1. `Model::GeneratedRelationMethods` holds all the relation methods with the return type of
      # `Model::PrivateRelation`. For example, calling `all` on the `Model` class or an instance of
      # `Model::PrivateRelation` class will always return a `Model::PrivateRelation` instance, thus the
      # signature of `all` is defined with that return type in this module.
      #
      # 2. `Model::GeneratedAssociationRelationMethods` holds all the relation methods with the return type
      # of `Model::PrivateAssociationRelation`. For example, calling `all` on an instance of
      # `Model::PrivateAssociationRelation` or an instance of `Model::PrivateCollectionProxy` class will
      # always return a `Model::PrivateAssociationRelation` instance, thus the signature of `all` is defined
      # with that return type in this module.
      #
      # 3. `Model::CommonRelationMethods` holds all the relation methods that do not depend on the type of
      # relation in their return type. For example, `find_by!` will always return the same type (a `Model`
      # instance), regardless of what kind of relation it is called on, and so belongs in this module.
      # This module is used to reduce the replication of methods between the previous two modules.
      #
      # Additionally, the actual `Model` class extends both `Model::CommonRelationMethods` and
      # `Model::PrivateRelation` modules, so that, for example, `find_by` and `all` can be chained off of the
      # `Model` class.
      #
      # **A note on find**: `find` is typed as `T.untyped` by default.
      #
      # While it is often used in the manner of `Model.find(id)`, Rails does support pasing in an array to find, which
      # would then return a `T::Enumerable[Model]`. This would force a static cast everywhere find is used to avoid type
      # errors. This is not ideal considering very few users of find use the array syntax over a where. With untyped,
      # this cast is optional and so it was decided to avoid typing it. If you need runtime guarentees when using `find`
      # the best method of doing so is by casting the return value to the model: `T.cast(Model.find(id), Model)`.
      # `find_by` does guarentee a return value of `Model`, so find can can be refactored accordingly:
      # `Model.find_by!(id: id)`. This will avoid the cast requirement at runtime.
      #
      # **CAUTION**: The generated relation classes are named `PrivateXXX` intentionally to reflect the fact
      # that they represent private subconstants of the Active Record model. As such, these types do not
      # exist at runtime, and their counterparts that do exist at runtime are marked `private_constant` anyway.
      # For that reason, these types cannot be used in user code or in `sig`s inside Ruby files, since that will
      # make the runtime checks fail.
      #
      # For example, with the following `ActiveRecord::Base` subclass:
      #
      # ~~~rb
      # class Post < ApplicationRecord
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `post.rbi` with the following content:
      # ~~~rbi
      # # post.rbi
      # # typed: true
      #
      # class Post
      #   extend CommonRelationMethods
      #   extend GeneratedRelationMethods
      #
      #   module CommonRelationMethods
      #     sig { params(block: T.nilable(T.proc.params(record: ::Post).returns(T.untyped))).returns(T::Boolean) }
      #     def any?(&block); end
      #
      #     # ...
      #   end
      #
      #   module GeneratedAssociationRelationMethods
      #     sig { returns(PrivateAssociationRelation) }
      #     def all; end
      #
      #     # ...
      #
      #     sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
      #     def where(*args, &blk); end
      #   end
      #
      #   module GeneratedRelationMethods
      #     sig { returns(PrivateRelation) }
      #     def all; end
      #
      #     # ...
      #
      #     sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
      #     def where(*args, &blk); end
      #   end
      #
      #   class PrivateAssociationRelation < ::ActiveRecord::AssociationRelation
      #     include CommonRelationMethods
      #     include GeneratedAssociationRelationMethods
      #
      #     sig { returns(T::Array[::Post]) }
      #     def to_ary; end
      #
      #     Elem = type_member { { fixed: ::Post } }
      #   end
      #
      #   class PrivateCollectionProxy < ::ActiveRecord::Associations::CollectionProxy
      #     include CommonRelationMethods
      #     include GeneratedAssociationRelationMethods
      #
      #     sig do
      #       params(records: T.any(::Post, T::Array[::Post], T::Array[PrivateCollectionProxy]))
      #         .returns(PrivateCollectionProxy)
      #     end
      #     def <<(*records); end
      #
      #     # ...
      #   end
      #
      #   class PrivateRelation < ::ActiveRecord::Relation
      #     include CommonRelationMethods
      #     include GeneratedRelationMethods
      #
      #     sig { returns(T::Array[::Post]) }
      #     def to_ary; end
      #
      #     Elem = type_member { { fixed: ::Post } }
      #   end
      # end
      # ~~~
      class ActiveRecordRelations < Compiler
        extend T::Sig
        include Helpers::ActiveRecordConstantsHelper
        include SorbetHelper

        ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

        sig { override.void }
        def decorate
          root.create_path(constant) do |model|
            relation_methods_module = model.create_module(RelationMethodsModuleName)
            association_relation_methods_module = model.create_module(AssociationRelationMethodsModuleName)
            common_relation_methods_module = model.create_module(CommonRelationMethodsModuleName)

            create_classes_and_includes(model)
            create_common_methods(common_relation_methods_module)
            create_relation_methods(relation_methods_module, association_relation_methods_module)
            create_association_relation_methods(association_relation_methods_module)
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            ActiveRecord::Base.descendants.reject(&:abstract_class?)
          end
        end

        ASSOCIATION_METHODS = T.let(
          ::ActiveRecord::AssociationRelation.instance_methods -
            ::ActiveRecord::Relation.instance_methods,
          T::Array[Symbol],
        )
        COLLECTION_PROXY_METHODS = T.let(
          ::ActiveRecord::Associations::CollectionProxy.instance_methods -
            ::ActiveRecord::AssociationRelation.instance_methods,
          T::Array[Symbol],
        )

        QUERY_METHODS = T.let(
          begin
            # Grab all Query methods
            query_methods = ActiveRecord::QueryMethods.instance_methods(false)
            # Grab all Spawn methods
            query_methods |= ActiveRecord::SpawnMethods.instance_methods(false)
            # Remove the ones we know are private API
            query_methods -= [:arel, :build_subquery, :construct_join_dependency, :extensions, :spawn]
            # Remove "where" which needs a custom return type for WhereChains
            query_methods -= [:where]
            # Remove the methods that ...
            query_methods
              .grep_v(/_clause$/) # end with "_clause"
              .grep_v(/_values?$/) # end with "_value" or "_values"
              .grep_v(/=$/) # end with "=""
              .grep_v(/(?<!uniq)!$/) # end with "!" except for "uniq!"
          end,
          T::Array[Symbol],
        )
        WHERE_CHAIN_QUERY_METHODS = T.let(
          ActiveRecord::QueryMethods::WhereChain.instance_methods(false),
          T::Array[Symbol],
        )
        FINDER_METHODS = T.let(ActiveRecord::FinderMethods.instance_methods(false), T::Array[Symbol])
        SIGNED_FINDER_METHODS = T.let(
          defined?(ActiveRecord::SignedId) ? ActiveRecord::SignedId::ClassMethods.instance_methods(false) : [],
          T::Array[Symbol],
        )
        BATCHES_METHODS = T.let(ActiveRecord::Batches.instance_methods(false), T::Array[Symbol])
        CALCULATION_METHODS = T.let(ActiveRecord::Calculations.instance_methods(false), T::Array[Symbol])
        ENUMERABLE_QUERY_METHODS = T.let([:any?, :many?, :none?, :one?], T::Array[Symbol])
        FIND_OR_CREATE_METHODS = T.let(
          [:find_or_create_by, :find_or_create_by!, :find_or_initialize_by, :create_or_find_by, :create_or_find_by!],
          T::Array[Symbol],
        )
        BUILDER_METHODS = T.let([:new, :build, :create, :create!], T::Array[Symbol])

        private

        sig { returns(String) }
        def constant_name
          @constant_name ||= T.let(T.must(qualified_name_of(constant)), T.nilable(String))
        end

        sig { params(method_name: Symbol).returns(T::Boolean) }
        def bang_method?(method_name)
          method_name.to_s.end_with?("!")
        end

        sig { params(model: RBI::Scope).void }
        def create_classes_and_includes(model)
          model.create_extend(CommonRelationMethodsModuleName)
          # The model always extends the generated relation module
          model.create_extend(RelationMethodsModuleName)

          # Type the `to_ary` method as returning `NilClass` so that flatten stops recursing
          # See https://github.com/sorbet/sorbet/pull/4706 for details
          model.create_method("to_ary", return_type: "NilClass", visibility: RBI::Private.new)

          create_relation_class(model)
          create_association_relation_class(model)
          create_collection_proxy_class(model)
        end

        sig { params(model: RBI::Scope).void }
        def create_relation_class(model)
          superclass = "::ActiveRecord::Relation"

          # The relation subclass includes the generated relation module
          model.create_class(RelationClassName, superclass_name: superclass) do |klass|
            klass.create_include(CommonRelationMethodsModuleName)
            klass.create_include(RelationMethodsModuleName)
            klass.create_type_variable("Elem", type: "type_member", fixed: constant_name)

            klass.create_method("to_ary", return_type: "T::Array[#{constant_name}]")
          end

          create_relation_where_chain_class(model)
        end

        sig { params(model: RBI::Scope).void }
        def create_association_relation_class(model)
          superclass = "::ActiveRecord::AssociationRelation"

          # Association subclasses include the generated association relation module
          model.create_class(AssociationRelationClassName, superclass_name: superclass) do |klass|
            klass.create_include(CommonRelationMethodsModuleName)
            klass.create_include(AssociationRelationMethodsModuleName)
            klass.create_type_variable("Elem", type: "type_member", fixed: constant_name)

            klass.create_method("to_ary", return_type: "T::Array[#{constant_name}]")
          end

          create_association_relation_where_chain_class(model)
        end

        sig { params(model: RBI::Scope).void }
        def create_relation_where_chain_class(model)
          model.create_class(RelationWhereChainClassName, superclass_name: RelationClassName) do |klass|
            create_where_chain_methods(klass, RelationClassName)
            klass.create_type_variable("Elem", type: "type_member", fixed: constant_name)
          end
        end

        sig { params(model: RBI::Scope).void }
        def create_association_relation_where_chain_class(model)
          model.create_class(
            AssociationRelationWhereChainClassName,
            superclass_name: AssociationRelationClassName,
          ) do |klass|
            create_where_chain_methods(klass, AssociationRelationClassName)
            klass.create_type_variable("Elem", type: "type_member", fixed: constant_name)
          end
        end

        sig { params(klass: RBI::Scope, return_type: String).void }
        def create_where_chain_methods(klass, return_type)
          WHERE_CHAIN_QUERY_METHODS.each do |method_name|
            case method_name
            when :not
              klass.create_method(
                method_name.to_s,
                parameters: [
                  create_param("opts", type: "T.untyped"),
                  create_rest_param("rest", type: "T.untyped"),
                ],
                return_type: return_type,
              )
            when :associated, :missing
              klass.create_method(
                method_name.to_s,
                parameters: [
                  create_rest_param("args", type: "T.untyped"),
                ],
                return_type: return_type,
              )
            end
          end
        end

        sig { params(model: RBI::Scope).void }
        def create_collection_proxy_class(model)
          superclass = "::ActiveRecord::Associations::CollectionProxy"

          # The relation subclass includes the generated association relation module
          model.create_class(AssociationsCollectionProxyClassName, superclass_name: superclass) do |klass|
            klass.create_include(CommonRelationMethodsModuleName)
            klass.create_include(AssociationRelationMethodsModuleName)
            klass.create_type_variable("Elem", type: "type_member", fixed: constant_name)

            klass.create_method("to_ary", return_type: "T::Array[#{constant_name}]")
            create_collection_proxy_methods(klass)
          end
        end

        sig { params(klass: RBI::Scope).void }
        def create_collection_proxy_methods(klass)
          # For these cases, it is valid to pass:
          # - a model instance, thus `Model`
          # - a model collection which can be:
          #   - an array of models, thus `T::Enumerable[Model]`
          #   - an association relation of a model, thus `T::Enumerable[Model]`
          #   - a collection proxy of a model, thus, again, a `T::Enumerable[Model]`
          #   - a collection of relations or collection proxies, thus `T::Enumerable[T::Enumerable[Model]]`
          #   - or, any mix of the above, thus `T::Enumerable[T.any(Model, T::Enumerable[Model])]`
          # which altogether gives us:
          #   `T.any(Model, T::Enumerable[T.any(Model, T::Enumerable[Model])])`
          model_collection =
            "T.any(#{constant_name}, T::Enumerable[T.any(#{constant_name}, T::Enumerable[#{constant_name}])])"

          # For these cases, it is valid to pass the above kind of things, but also:
          # - a model identifier, which can be:
          #   - a numeric id, thus `Integer`
          #   - a string id, thus `String`
          # - a collection of identifiers
          #   - a collection of identifiers, thus `T::Enumerable[T.any(Integer, String)]`
          # which, coupled with the above case, gives us:
          #   `T.any(Model, Integer, String, T::Enumerable[T.any(Model, Integer, String, T::Enumerable[Model])])`
          model_or_id_collection =
            "T.any(#{constant_name}, Integer, String" \
              ", T::Enumerable[T.any(#{constant_name}, Integer, String, T::Enumerable[#{constant_name}])])"

          COLLECTION_PROXY_METHODS.each do |method_name|
            case method_name
            when :<<, :append, :concat, :prepend, :push
              klass.create_method(
                method_name.to_s,
                parameters: [
                  create_rest_param("records", type: model_collection),
                ],
                return_type: AssociationsCollectionProxyClassName,
              )
            when :clear
              klass.create_method(
                method_name.to_s,
                return_type: AssociationsCollectionProxyClassName,
              )
            when :delete, :destroy
              klass.create_method(
                method_name.to_s,
                parameters: [
                  create_rest_param("records", type: model_or_id_collection),
                ],
                return_type: "T::Array[#{constant_name}]",
              )
            when :load_target
              klass.create_method(
                method_name.to_s,
                return_type: "T::Array[#{constant_name}]",
              )
            when :replace
              klass.create_method(
                method_name.to_s,
                parameters: [
                  create_param("other_array", type: model_collection),
                ],
                return_type: "T::Array[#{constant_name}]",
              )
            when :reset_scope
              # skip
            when :scope
              klass.create_method(
                method_name.to_s,
                return_type: AssociationRelationClassName,
              )
            when :target
              klass.create_method(
                method_name.to_s,
                return_type: "T::Array[#{constant_name}]",
              )
            end
          end
        end

        sig { params(relation_methods_module: RBI::Scope, association_relation_methods_module: RBI::Scope).void }
        def create_relation_methods(relation_methods_module, association_relation_methods_module)
          create_relation_method("all", relation_methods_module, association_relation_methods_module)
          create_relation_method(
            "where",
            relation_methods_module,
            association_relation_methods_module,
            parameters: [
              create_rest_param("args", type: "T.untyped"),
              create_block_param("blk", type: "T.untyped"),
            ],
            relation_return_type: RelationWhereChainClassName,
            association_return_type: AssociationRelationWhereChainClassName,
          )

          QUERY_METHODS.each do |method_name|
            create_relation_method(
              method_name,
              relation_methods_module,
              association_relation_methods_module,
              parameters: [
                create_rest_param("args", type: "T.untyped"),
                create_block_param("blk", type: "T.untyped"),
              ],
            )
          end
        end

        sig { params(association_relation_methods_module: RBI::Scope).void }
        def create_association_relation_methods(association_relation_methods_module)
          returning_type = "T.nilable(T.any(T::Array[Symbol], FalseClass))"
          unique_by_type = "T.nilable(T.any(T::Array[Symbol], Symbol))"

          ASSOCIATION_METHODS.each do |method_name|
            case method_name
            when :insert_all, :insert_all!, :upsert_all
              parameters = [
                create_param("attributes", type: "T::Array[Hash]"),
                create_kw_opt_param("returning", type: returning_type, default: "nil"),
              ]

              # Bang methods don't have the `unique_by` parameter
              unless bang_method?(method_name)
                parameters << create_kw_opt_param("unique_by", type: unique_by_type, default: "nil")
              end

              association_relation_methods_module.create_method(
                method_name.to_s,
                parameters: parameters,
                return_type: "ActiveRecord::Result",
              )
            when :insert, :insert!, :upsert
              parameters = [
                create_param("attributes", type: "Hash"),
                create_kw_opt_param("returning", type: returning_type, default: "nil"),
              ]

              # Bang methods don't have the `unique_by` parameter
              unless bang_method?(method_name)
                parameters << create_kw_opt_param("unique_by", type: unique_by_type, default: "nil")
              end

              association_relation_methods_module.create_method(
                method_name.to_s,
                parameters: parameters,
                return_type: "ActiveRecord::Result",
              )
            when :proxy_association
              # skip - private method
            end
          end
        end

        sig { params(common_relation_methods_module: RBI::Scope).void }
        def create_common_methods(common_relation_methods_module)
          create_common_method(
            "destroy_all",
            common_relation_methods_module,
            return_type: "T::Array[#{constant_name}]",
          )

          FINDER_METHODS.each do |method_name|
            case method_name
            when :exists?
              create_common_method(
                "exists?",
                common_relation_methods_module,
                parameters: [
                  create_opt_param("conditions", type: "T.untyped", default: ":none"),
                ],
                return_type: "T::Boolean",
              )
            when :include?, :member?
              create_common_method(
                method_name,
                common_relation_methods_module,
                parameters: [
                  create_param("record", type: "T.untyped"),
                ],
                return_type: "T::Boolean",
              )
            when :find
              create_common_method(
                "find",
                common_relation_methods_module,
                parameters: [
                  create_rest_param("args", type: "T.untyped"),
                ],
                return_type: "T.untyped",
              )
            when :find_by
              create_common_method(
                "find_by",
                common_relation_methods_module,
                parameters: [
                  create_rest_param("args", type: "T.untyped"),
                ],
                return_type: as_nilable_type(constant_name),
              )
            when :find_by!
              create_common_method(
                "find_by!",
                common_relation_methods_module,
                parameters: [
                  create_rest_param("args", type: "T.untyped"),
                ],
                return_type: constant_name,
              )
            when :find_sole_by
              create_common_method(
                "find_sole_by",
                common_relation_methods_module,
                parameters: [
                  create_param("arg", type: "T.untyped"),
                  create_rest_param("args", type: "T.untyped"),
                ],
                return_type: constant_name,
              )
            when :sole
              create_common_method(
                "sole",
                common_relation_methods_module,
                parameters: [],
                return_type: constant_name,
              )
            when :first, :last, :take
              create_common_method(
                method_name,
                common_relation_methods_module,
                parameters: [
                  create_opt_param("limit", type: "T.untyped", default: "nil"),
                ],
                return_type: "T.untyped",
              )
            when :raise_record_not_found_exception!
              # skip
            else
              return_type = if bang_method?(method_name)
                constant_name
              else
                as_nilable_type(constant_name)
              end

              create_common_method(
                method_name,
                common_relation_methods_module,
                return_type: return_type,
              )
            end
          end

          SIGNED_FINDER_METHODS.each do |method_name|
            case method_name
            when :find_signed
              create_common_method(
                "find_signed",
                common_relation_methods_module,
                parameters: [
                  create_param("signed_id", type: "T.untyped"),
                  create_kw_opt_param("purpose", type: "T.untyped", default: "nil"),
                ],
                return_type: as_nilable_type(constant_name),
              )
            when :find_signed!
              create_common_method(
                "find_signed!",
                common_relation_methods_module,
                parameters: [
                  create_param("signed_id", type: "T.untyped"),
                  create_kw_opt_param("purpose", type: "T.untyped", default: "nil"),
                ],
                return_type: constant_name,
              )
            end
          end

          CALCULATION_METHODS.each do |method_name|
            case method_name
            when :average, :maximum, :minimum
              create_common_method(
                method_name,
                common_relation_methods_module,
                parameters: [
                  create_param("column_name", type: "T.any(String, Symbol)"),
                ],
                return_type: "T.untyped",
              )
            when :calculate
              create_common_method(
                "calculate",
                common_relation_methods_module,
                parameters: [
                  create_param("operation", type: "Symbol"),
                  create_param("column_name", type: "T.any(String, Symbol)"),
                ],
                return_type: "T.untyped",
              )
            when :count
              create_common_method(
                "count",
                common_relation_methods_module,
                parameters: [
                  create_opt_param("column_name", type: "T.untyped", default: "nil"),
                ],
                return_type: "T.untyped",
              )
            when :ids
              create_common_method("ids", common_relation_methods_module, return_type: "Array")
            when :pick, :pluck
              create_common_method(
                method_name,
                common_relation_methods_module,
                parameters: [
                  create_rest_param("column_names", type: "T.untyped"),
                ],
                return_type: "T.untyped",
              )
            when :sum
              create_common_method(
                "sum",
                common_relation_methods_module,
                parameters: [
                  create_opt_param("column_name", type: "T.nilable(T.any(String, Symbol))", default: "nil"),
                  create_block_param("block", type: "T.nilable(T.proc.params(record: T.untyped).returns(T.untyped))"),
                ],
                return_type: "T.untyped",
              )
            end
          end

          BATCHES_METHODS.each do |method_name|
            case method_name
            when :find_each
              order = ActiveRecord::Batches.instance_method(:find_each).parameters.include?([:key, :order])
              create_common_method(
                "find_each",
                common_relation_methods_module,
                parameters: [
                  create_kw_opt_param("start", type: "T.untyped", default: "nil"),
                  create_kw_opt_param("finish", type: "T.untyped", default: "nil"),
                  create_kw_opt_param("batch_size", type: "Integer", default: "1000"),
                  create_kw_opt_param("error_on_ignore", type: "T.untyped", default: "nil"),
                  *(create_kw_opt_param("order", type: "Symbol", default: ":asc") if order),
                  create_block_param("block", type: "T.nilable(T.proc.params(object: #{constant_name}).void)"),
                ],
                return_type: "T.nilable(T::Enumerator[#{constant_name}])",
              )
            when :find_in_batches
              order = ActiveRecord::Batches.instance_method(:find_in_batches).parameters.include?([:key, :order])
              create_common_method(
                "find_in_batches",
                common_relation_methods_module,
                parameters: [
                  create_kw_opt_param("start", type: "T.untyped", default: "nil"),
                  create_kw_opt_param("finish", type: "T.untyped", default: "nil"),
                  create_kw_opt_param("batch_size", type: "Integer", default: "1000"),
                  create_kw_opt_param("error_on_ignore", type: "T.untyped", default: "nil"),
                  *(create_kw_opt_param("order", type: "Symbol", default: ":asc") if order),
                  create_block_param(
                    "block",
                    type: "T.nilable(T.proc.params(object: T::Array[#{constant_name}]).void)",
                  ),
                ],
                return_type: "T.nilable(T::Enumerator[T::Enumerator[#{constant_name}]])",
              )
            when :in_batches
              order = ActiveRecord::Batches.instance_method(:in_batches).parameters.include?([:key, :order])
              use_ranges = ActiveRecord::Batches.instance_method(:in_batches).parameters.include?([:key, :use_ranges])
              create_common_method(
                "in_batches",
                common_relation_methods_module,
                parameters: [
                  create_kw_opt_param("of", type: "Integer", default: "1000"),
                  create_kw_opt_param("start", type: "T.untyped", default: "nil"),
                  create_kw_opt_param("finish", type: "T.untyped", default: "nil"),
                  create_kw_opt_param("load", type: "T.untyped", default: "false"),
                  create_kw_opt_param("error_on_ignore", type: "T.untyped", default: "nil"),
                  *(create_kw_opt_param("order", type: "Symbol", default: ":asc") if order),
                  *(create_kw_opt_param("use_ranges", type: "T.untyped", default: "nil") if use_ranges),
                  create_block_param("block", type: "T.nilable(T.proc.params(object: #{RelationClassName}).void)"),
                ],
                return_type: "T.nilable(::ActiveRecord::Batches::BatchEnumerator)",
              )
            end
          end

          ENUMERABLE_QUERY_METHODS.each do |method_name|
            block_type = "T.nilable(T.proc.params(record: #{constant_name}).returns(T.untyped))"
            create_common_method(
              method_name,
              common_relation_methods_module,
              parameters: [
                create_block_param("block", type: block_type),
              ],
              return_type: "T::Boolean",
            )
          end

          FIND_OR_CREATE_METHODS.each do |method_name|
            block_type = "T.nilable(T.proc.params(object: #{constant_name}).void)"
            create_common_method(
              method_name,
              common_relation_methods_module,
              parameters: [
                create_param("attributes", type: "T.untyped"),
                create_block_param("block", type: block_type),
              ],
              return_type: constant_name,
            )
          end

          BUILDER_METHODS.each do |method_name|
            create_common_method(
              method_name,
              common_relation_methods_module,
              parameters: [
                create_opt_param("attributes", type: "T.untyped", default: "nil"),
                create_block_param("block", type: "T.nilable(T.proc.params(object: #{constant_name}).void)"),
              ],
              return_type: constant_name,
            )
          end
        end

        sig do
          params(
            name: T.any(Symbol, String),
            common_relation_methods_module: RBI::Scope,
            parameters: T::Array[RBI::TypedParam],
            return_type: T.nilable(String),
          ).void
        end
        def create_common_method(name, common_relation_methods_module, parameters: [], return_type: nil)
          common_relation_methods_module.create_method(
            name.to_s,
            parameters: parameters,
            return_type: return_type || "void",
          )
        end

        sig do
          params(
            name: T.any(Symbol, String),
            relation_methods_module: RBI::Scope,
            association_relation_methods_module: RBI::Scope,
            parameters: T::Array[RBI::TypedParam],
            relation_return_type: String,
            association_return_type: String,
          ).void
        end
        def create_relation_method(
          name,
          relation_methods_module,
          association_relation_methods_module,
          parameters: [],
          relation_return_type: RelationClassName,
          association_return_type: AssociationRelationClassName
        )
          relation_methods_module.create_method(
            name.to_s,
            parameters: parameters,
            return_type: relation_return_type,
          )
          association_relation_methods_module.create_method(
            name.to_s,
            parameters: parameters,
            return_type: association_return_type,
          )
        end
      end
    end
  end
end
