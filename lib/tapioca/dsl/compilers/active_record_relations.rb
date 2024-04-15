# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveRecord::Base)

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
      #     def to_a; end
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
      #     def to_a; end
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
          create_classes_and_includes
          create_common_methods
          create_relation_methods
          create_association_relation_methods
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
            # Remove "group" which needs a custom return type for GroupChains
            query_methods -= [:group]
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
        TO_ARRAY_METHODS = T.let([:to_ary, :to_a], T::Array[Symbol])

        private

        sig { returns(RBI::Scope) }
        def model
          @model ||= T.let(
            root.create_path(constant),
            T.nilable(RBI::Scope),
          )
        end

        sig { returns(RBI::Scope) }
        def relation_methods_module
          @relation_methods_module ||= T.let(
            model.create_module(RelationMethodsModuleName),
            T.nilable(RBI::Scope),
          )
        end

        sig { returns(RBI::Scope) }
        def association_relation_methods_module
          @association_relation_methods_module ||= T.let(
            model.create_module(AssociationRelationMethodsModuleName),
            T.nilable(RBI::Scope),
          )
        end

        sig { returns(RBI::Scope) }
        def common_relation_methods_module
          @common_relation_methods_module ||= T.let(
            model.create_module(CommonRelationMethodsModuleName),
            T.nilable(RBI::Scope),
          )
        end

        sig { returns(String) }
        def constant_name
          @constant_name ||= T.let(T.must(qualified_name_of(constant)), T.nilable(String))
        end

        sig { params(method_name: Symbol).returns(T::Boolean) }
        def bang_method?(method_name)
          method_name.to_s.end_with?("!")
        end

        sig { void }
        def create_classes_and_includes
          model.create_extend(CommonRelationMethodsModuleName)
          # The model always extends the generated relation module
          model.create_extend(RelationMethodsModuleName)

          # Type the `to_ary` method as returning `NilClass` so that flatten stops recursing
          # See https://github.com/sorbet/sorbet/pull/4706 for details
          model.create_method("to_ary", return_type: "NilClass", visibility: RBI::Private.new)

          create_relation_class
          create_association_relation_class
          create_collection_proxy_class
        end

        sig { void }
        def create_relation_class
          superclass = "::ActiveRecord::Relation"

          # The relation subclass includes the generated relation module
          model.create_class(RelationClassName, superclass_name: superclass) do |klass|
            klass.create_include(CommonRelationMethodsModuleName)
            klass.create_include(RelationMethodsModuleName)
            klass.create_type_variable("Elem", type: "type_member", fixed: constant_name)

            TO_ARRAY_METHODS.each do |method_name|
              klass.create_method(method_name.to_s, return_type: "T::Array[#{constant_name}]")
            end
          end

          create_relation_group_chain_class
          create_relation_where_chain_class
        end

        sig { void }
        def create_association_relation_class
          superclass = "::ActiveRecord::AssociationRelation"

          # Association subclasses include the generated association relation module
          model.create_class(AssociationRelationClassName, superclass_name: superclass) do |klass|
            klass.create_include(CommonRelationMethodsModuleName)
            klass.create_include(AssociationRelationMethodsModuleName)
            klass.create_type_variable("Elem", type: "type_member", fixed: constant_name)

            TO_ARRAY_METHODS.each do |method_name|
              klass.create_method(method_name.to_s, return_type: "T::Array[#{constant_name}]")
            end
          end

          create_association_relation_group_chain_class
          create_association_relation_where_chain_class
        end

        sig { void }
        def create_relation_group_chain_class
          model.create_class(RelationGroupChainClassName, superclass_name: RelationClassName) do |klass|
            create_group_chain_methods(klass)
            klass.create_type_variable("Elem", type: "type_member", fixed: constant_name)
          end
        end

        sig { void }
        def create_association_relation_group_chain_class
          model.create_class(
            AssociationRelationGroupChainClassName,
            superclass_name: AssociationRelationClassName,
          ) do |klass|
            create_group_chain_methods(klass)
            klass.create_type_variable("Elem", type: "type_member", fixed: constant_name)
          end
        end

        sig { params(klass: RBI::Scope).void }
        def create_group_chain_methods(klass)
          # Calculation methods used with `group` return a hash where the keys cannot be typed
          # but the values can. Technically a `group` anywhere in the query chain produces
          # this behavior but to avoid needing to re-type every query method inside this module
          # we make a simplifying assumption that the calculation method is called immediately
          # after the group (e.g. `group().count` and not `group().where().count`). The one
          # exception is `group().having().count` which is fairly idiomatic so that gets handled
          # without breaking the chain.
          klass.create_method(
            "having",
            parameters: [
              create_rest_param("args", type: "T.untyped"),
              create_block_param("blk", type: "T.untyped"),
            ],
            return_type: "T.self_type",
          )

          CALCULATION_METHODS.each do |method_name|
            case method_name
            when :average, :maximum, :minimum
              klass.create_method(
                method_name.to_s,
                parameters: [
                  create_param("column_name", type: "T.any(String, Symbol)"),
                ],
                return_type: "T::Hash[T.untyped, #{method_name == :average ? "Numeric" : "T.untyped"}]",
              )
            when :calculate
              klass.create_method(
                "calculate",
                parameters: [
                  create_param("operation", type: "Symbol"),
                  create_param("column_name", type: "T.any(String, Symbol)"),
                ],
                return_type: "T::Hash[T.untyped, Numeric]",
              )
            when :count
              klass.create_method(
                "count",
                parameters: [
                  create_opt_param("column_name", type: "T.untyped", default: "nil"),
                ],
                return_type: "T::Hash[T.untyped, Integer]",
              )
            when :sum
              klass.create_method(
                "sum",
                parameters: [
                  create_opt_param("column_name", type: "T.nilable(T.any(String, Symbol))", default: "nil"),
                  create_block_param("block", type: "T.nilable(T.proc.params(record: T.untyped).returns(T.untyped))"),
                ],
                return_type: "T::Hash[T.untyped, Numeric]",
              )
            end
          end
        end

        sig { void }
        def create_relation_where_chain_class
          model.create_class(RelationWhereChainClassName, superclass_name: RelationClassName) do |klass|
            create_where_chain_methods(klass, RelationClassName)
            klass.create_type_variable("Elem", type: "type_member", fixed: constant_name)
          end
        end

        sig { void }
        def create_association_relation_where_chain_class
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

        sig { void }
        def create_collection_proxy_class
          superclass = "::ActiveRecord::Associations::CollectionProxy"

          # The relation subclass includes the generated association relation module
          model.create_class(AssociationsCollectionProxyClassName, superclass_name: superclass) do |klass|
            klass.create_include(CommonRelationMethodsModuleName)
            klass.create_include(AssociationRelationMethodsModuleName)
            klass.create_type_variable("Elem", type: "type_member", fixed: constant_name)

            TO_ARRAY_METHODS.each do |method_name|
              klass.create_method(method_name.to_s, return_type: "T::Array[#{constant_name}]")
            end
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

        sig { void }
        def create_relation_methods
          create_relation_method("all")
          create_relation_method(
            "group",
            parameters: [
              create_rest_param("args", type: "T.untyped"),
              create_block_param("blk", type: "T.untyped"),
            ],
            relation_return_type: RelationGroupChainClassName,
            association_return_type: AssociationRelationGroupChainClassName,
          )
          create_relation_method(
            "where",
            parameters: [
              create_rest_param("args", type: "T.untyped"),
              create_block_param("blk", type: "T.untyped"),
            ],
            relation_return_type: RelationWhereChainClassName,
            association_return_type: AssociationRelationWhereChainClassName,
          )

          QUERY_METHODS.each do |method_name|
            case method_name
            when :extract_associated
              parameters = [create_param("association", type: "Symbol")]
              return_type = "T::Array[T.untyped]"
              relation_methods_module.create_method(
                method_name.to_s,
                parameters: parameters,
                return_type: return_type,
              )
              association_relation_methods_module.create_method(
                method_name.to_s,
                parameters: parameters,
                return_type: return_type,
              )
            else
              create_relation_method(
                method_name,
                parameters: [
                  create_rest_param("args", type: "T.untyped"),
                  create_block_param("blk", type: "T.untyped"),
                ],
              )
            end
          end
        end

        sig { void }
        def create_association_relation_methods
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

        sig { void }
        def create_common_methods
          create_common_method(
            "destroy_all",
            return_type: "T::Array[#{constant_name}]",
          )

          FINDER_METHODS.each do |method_name|
            case method_name
            when :exists?
              create_common_method(
                "exists?",
                parameters: [
                  create_opt_param("conditions", type: "T.untyped", default: ":none"),
                ],
                return_type: "T::Boolean",
              )
            when :include?, :member?
              create_common_method(
                method_name,
                parameters: [
                  create_param("record", type: "T.untyped"),
                ],
                return_type: "T::Boolean",
              )
            when :find
              # From ActiveRecord::ConnectionAdapter::Quoting#quote, minus nil
              id_types = "T.any(String, Symbol, ::ActiveSupport::Multibyte::Chars, T::Boolean, BigDecimal, Numeric, " \
                "::ActiveRecord::Type::Binary::Data, ::ActiveRecord::Type::Time::Value, Date, Time, " \
                "::ActiveSupport::Duration, T::Class[T.anything])"
              array_type = if constant.try(:composite_primary_key?)
                "T::Array[T::Array[#{id_types}]]"
              else
                "T::Array[#{id_types}]"
              end
              sigs = [
                common_relation_methods_module.create_sig(
                  parameters: { args: id_types },
                  return_type: constant_name,
                ),
                common_relation_methods_module.create_sig(
                  parameters: { args: array_type },
                  return_type: "T::Enumerable[#{constant_name}]",
                ),
                common_relation_methods_module.create_sig(
                  parameters: {
                    args: "NilClass",
                    block: "T.proc.params(object: #{constant_name}).void",
                  },
                  return_type: as_nilable_type(constant_name),
                ),
              ]
              common_relation_methods_module.create_method_with_sigs(
                "find",
                sigs: sigs,
                parameters: [RBI::OptParam.new("args", "nil"), RBI::BlockParam.new("block")],
              )
            when :find_by
              create_common_method(
                "find_by",
                parameters: [
                  create_rest_param("args", type: "T.untyped"),
                ],
                return_type: as_nilable_type(constant_name),
              )
            when :find_by!
              create_common_method(
                "find_by!",
                parameters: [
                  create_rest_param("args", type: "T.untyped"),
                ],
                return_type: constant_name,
              )
            when :find_sole_by
              create_common_method(
                "find_sole_by",
                parameters: [
                  create_param("arg", type: "T.untyped"),
                  create_rest_param("args", type: "T.untyped"),
                ],
                return_type: constant_name,
              )
            when :sole
              create_common_method(
                "sole",
                parameters: [],
                return_type: constant_name,
              )
            when :first, :last, :take
              sigs = [
                common_relation_methods_module.create_sig(
                  parameters: { limit: "NilClass" },
                  return_type: as_nilable_type(constant_name),
                ),
                common_relation_methods_module.create_sig(
                  parameters: { limit: "Integer" },
                  return_type: "T::Array[#{constant_name}]",
                ),
              ]
              common_relation_methods_module.create_method_with_sigs(
                method_name.to_s,
                sigs: sigs,
                parameters: [RBI::OptParam.new("limit", "nil")],
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
                return_type: return_type,
              )
            end
          end

          SIGNED_FINDER_METHODS.each do |method_name|
            case method_name
            when :find_signed
              create_common_method(
                "find_signed",
                parameters: [
                  create_param("signed_id", type: "T.untyped"),
                  create_kw_opt_param("purpose", type: "T.untyped", default: "nil"),
                ],
                return_type: as_nilable_type(constant_name),
              )
            when :find_signed!
              create_common_method(
                "find_signed!",
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
                parameters: [
                  create_param("column_name", type: "T.any(String, Symbol)"),
                ],
                return_type: method_name == :average ? "Numeric" : "T.untyped",
              )
            when :calculate
              create_common_method(
                "calculate",
                parameters: [
                  create_param("operation", type: "Symbol"),
                  create_param("column_name", type: "T.any(String, Symbol)"),
                ],
                return_type: "Numeric",
              )
            when :count
              sigs = [
                common_relation_methods_module.create_sig(
                  parameters: { column_name: "T.nilable(T.any(String, Symbol))" },
                  return_type: "Integer",
                ),
                common_relation_methods_module.create_sig(
                  parameters: { column_name: "NilClass", block: "T.proc.params(object: #{constant_name}).void" },
                  return_type: "Integer",
                ),
              ]
              common_relation_methods_module.create_method_with_sigs(
                "count",
                sigs: sigs,
                parameters: [
                  RBI::OptParam.new("column_name", "nil"),
                  RBI::BlockParam.new("block"),
                ],
              )
            when :ids
              create_common_method("ids", return_type: "Array")
            when :pick, :pluck
              create_common_method(
                method_name,
                parameters: [
                  create_rest_param("column_names", type: "T.untyped"),
                ],
                return_type: "T.untyped",
              )
            when :sum
              create_common_method(
                "sum",
                parameters: [
                  create_opt_param("column_name", type: "T.nilable(T.any(String, Symbol))", default: "nil"),
                  create_block_param("block", type: "T.nilable(T.proc.params(record: T.untyped).returns(T.untyped))"),
                ],
                return_type: "Numeric",
              )
            end
          end

          BATCHES_METHODS.each do |method_name|
            case method_name
            when :find_each
              order = ActiveRecord::Batches.instance_method(:find_each).parameters.include?([:key, :order])
              parameters = {
                start: "T.untyped",
                finish: "T.untyped",
                batch_size: "Integer",
                error_on_ignore: "T.untyped",
                order: ("Symbol" if order),
              }.compact
              sigs = [
                common_relation_methods_module.create_sig(
                  parameters: parameters.merge(block: "T.proc.params(object: #{constant_name}).void"),
                  return_type: "void",
                ),
                common_relation_methods_module.create_sig(
                  parameters: parameters,
                  return_type: "T::Enumerator[#{constant_name}]",
                ),
              ]
              common_relation_methods_module.create_method_with_sigs(
                "find_each",
                sigs: sigs,
                parameters: [
                  RBI::KwOptParam.new("start", "nil"),
                  RBI::KwOptParam.new("finish", "nil"),
                  RBI::KwOptParam.new("batch_size", "1000"),
                  RBI::KwOptParam.new("error_on_ignore", "nil"),
                  *(RBI::KwOptParam.new("order", ":asc") if order),
                  RBI::BlockParam.new("block"),
                ],
              )
            when :find_in_batches
              order = ActiveRecord::Batches.instance_method(:find_in_batches).parameters.include?([:key, :order])
              parameters = {
                start: "T.untyped",
                finish: "T.untyped",
                batch_size: "Integer",
                error_on_ignore: "T.untyped",
                order: ("Symbol" if order),
              }.compact
              sigs = [
                common_relation_methods_module.create_sig(
                  parameters: parameters.merge(block: "T.proc.params(object: T::Array[#{constant_name}]).void"),
                  return_type: "void",
                ),
                common_relation_methods_module.create_sig(
                  parameters: parameters,
                  return_type: "T::Enumerator[T::Enumerator[#{constant_name}]]",
                ),
              ]
              common_relation_methods_module.create_method_with_sigs(
                "find_in_batches",
                sigs: sigs,
                parameters: [
                  RBI::KwOptParam.new("start", "nil"),
                  RBI::KwOptParam.new("finish", "nil"),
                  RBI::KwOptParam.new("batch_size", "1000"),
                  RBI::KwOptParam.new("error_on_ignore", "nil"),
                  *(RBI::KwOptParam.new("order", ":asc") if order),
                  RBI::BlockParam.new("block"),
                ],
              )
            when :in_batches
              order = ActiveRecord::Batches.instance_method(:in_batches).parameters.include?([:key, :order])
              use_ranges = ActiveRecord::Batches.instance_method(:in_batches).parameters.include?([:key, :use_ranges])
              parameters = {
                of: "Integer",
                start: "T.untyped",
                finish: "T.untyped",
                load: "T.untyped",
                error_on_ignore: "T.untyped",
                order: ("Symbol" if order),
                use_ranges: ("T.untyped" if use_ranges),
              }.compact
              sigs = [
                common_relation_methods_module.create_sig(
                  parameters: parameters.merge(block: "T.proc.params(object: #{RelationClassName}).void"),
                  return_type: "void",
                ),
                common_relation_methods_module.create_sig(
                  parameters: parameters,
                  return_type: "::ActiveRecord::Batches::BatchEnumerator",
                ),
              ]
              common_relation_methods_module.create_method_with_sigs(
                "in_batches",
                sigs: sigs,
                parameters: [
                  RBI::KwOptParam.new("of", "1000"),
                  RBI::KwOptParam.new("start", "nil"),
                  RBI::KwOptParam.new("finish", "nil"),
                  RBI::KwOptParam.new("load", "false"),
                  RBI::KwOptParam.new("error_on_ignore", "nil"),
                  *(RBI::KwOptParam.new("order", ":asc") if order),
                  *(RBI::KwOptParam.new("use_ranges", "nil") if use_ranges),
                  RBI::BlockParam.new("block"),
                ],
              )
            end
          end

          ENUMERABLE_QUERY_METHODS.each do |method_name|
            block_type = "T.nilable(T.proc.params(record: #{constant_name}).returns(T.untyped))"
            create_common_method(
              method_name,
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
            parameters: T::Array[RBI::TypedParam],
            return_type: T.nilable(String),
          ).void
        end
        def create_common_method(name, parameters: [], return_type: nil)
          common_relation_methods_module.create_method(
            name.to_s,
            parameters: parameters,
            return_type: return_type || "void",
          )
        end

        sig do
          params(
            name: T.any(Symbol, String),
            parameters: T::Array[RBI::TypedParam],
            relation_return_type: String,
            association_return_type: String,
          ).void
        end
        def create_relation_method(
          name,
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
