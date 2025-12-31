# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveRecord::Base)

require "tapioca/dsl/helpers/active_model_type_helper"
require "tapioca/dsl/helpers/active_record_column_type_helper"
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
      # 2. `Model::PrivateAssociationRelation` that subclasses `ActiveRecord::AssociationRelation`. This synthetic
      # class represents a relation on a singular association of type `Model` (e.g. `foo.model`) whose methods which
      # return a relation will always return a `Model::PrivateAssociationRelation` instance. The difference between this
      # class and the previous one is mainly that an association relation also keeps track of the resource association
      # for this relation.
      #
      # 3. `Model::PrivateCollectionProxy` that subclasses from `ActiveRecord::Associations::CollectionProxy`.
      # This synthetic class represents a relation on a plural association of type `Model` (e.g. `foo.models`)
      # whose methods which return a relation will always return a `Model::PrivateAssociationRelation` instance.
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
      #: [ConstantType = singleton(::ActiveRecord::Base)]
      class ActiveRecordRelations < Compiler
        extend T::Sig
        include Helpers::ActiveRecordConstantsHelper
        include SorbetHelper

        # From ActiveRecord::ConnectionAdapter::Quoting#quote, minus nil
        ID_TYPES = [
          "String",
          "Symbol",
          "::ActiveSupport::Multibyte::Chars",
          "T::Boolean",
          "BigDecimal",
          "Numeric",
          "::ActiveRecord::Type::Binary::Data",
          "::ActiveRecord::Type::Time::Value",
          "Date",
          "Time",
          "::ActiveSupport::Duration",
          "T::Class[T.anything]",
        ].to_set.freeze #: Set[String]

        # @override
        #: -> void
        def decorate
          create_classes_and_includes
          create_common_methods
          create_relation_methods
          create_association_relation_methods
        end

        class << self
          extend T::Sig

          # @override
          #: -> Enumerable[T::Module[top]]
          def gather_constants
            ActiveRecord::Base.descendants.reject(&:abstract_class?)
          end
        end

        ASSOCIATION_METHODS = ::ActiveRecord::AssociationRelation.instance_methods -
          ::ActiveRecord::Relation.instance_methods #: Array[Symbol]
        COLLECTION_PROXY_METHODS = ::ActiveRecord::Associations::CollectionProxy.instance_methods -
          ::ActiveRecord::AssociationRelation.instance_methods #: Array[Symbol]

        QUERY_METHODS = begin
          # Grab all Query methods
          query_methods = ActiveRecord::QueryMethods.instance_methods(false)
          # Grab all Spawn methods
          query_methods |= ActiveRecord::SpawnMethods.instance_methods(false)
          # Remove the ones we know are private API
          query_methods -= [:all, :arel, :build_subquery, :construct_join_dependency, :extensions, :spawn]
          # Remove the methods that ...
          query_methods
            .grep_v(/_clause$/) # end with "_clause"
            .grep_v(/_values?$/) # end with "_value" or "_values"
            .grep_v(/=$/) # end with "=""
            .grep_v(/(?<!uniq)!$/) # end with "!" except for "uniq!"
        end #: Array[Symbol]
        WHERE_CHAIN_QUERY_METHODS = ActiveRecord::QueryMethods::WhereChain.instance_methods(false) #: Array[Symbol]
        FINDER_METHODS = ActiveRecord::FinderMethods.instance_methods(false) #: Array[Symbol]
        SIGNED_FINDER_METHODS = if defined?(ActiveRecord::SignedId)
          ActiveRecord::SignedId::ClassMethods.instance_methods(false)
        else
          []
        end #: Array[Symbol]
        BATCHES_METHODS = ActiveRecord::Batches.instance_methods(false) #: Array[Symbol]
        BATCHES_METHODS_PARAMETERS = {
          start: ["T.untyped", "nil"],
          finish: ["T.untyped", "nil"],
          load: ["T.untyped", "false"],
          batch_size: ["Integer", "1000"],
          of: ["Integer", "1000"],
          error_on_ignore: ["T.untyped", "nil"],
          order: ["Symbol", ":asc"],
          cursor: ["T.untyped", "primary_key"],
          use_ranges: ["T.untyped", "nil"],
        } #: Hash[Symbol, [String, String]]
        CALCULATION_METHODS = ActiveRecord::Calculations.instance_methods(false) #: Array[Symbol]
        RELATION_METHODS = ActiveRecord::Relation.instance_methods(false) #: Array[Symbol]
        TO_ARRAY_METHODS = [:to_ary, :to_a] #: Array[Symbol]

        private

        #: -> RBI::Scope
        def model
          @model ||= root.create_path(constant) #: RBI::Scope?
        end

        #: -> RBI::Scope
        def relation_methods_module
          @relation_methods_module ||= model.create_module(RelationMethodsModuleName) #: RBI::Scope?
        end

        #: -> RBI::Scope
        def association_relation_methods_module
          @association_relation_methods_module ||=
            model.create_module(AssociationRelationMethodsModuleName) #: RBI::Scope?
        end

        #: -> RBI::Scope
        def common_relation_methods_module
          @common_relation_methods_module ||= model.create_module(CommonRelationMethodsModuleName) #: RBI::Scope?
        end

        #: -> String
        def constant_name
          @constant_name ||= T.must(qualified_name_of(constant)) #: String?
        end

        #: (Symbol method_name) -> bool
        def bang_method?(method_name)
          method_name.to_s.end_with?("!")
        end

        #: -> void
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

        #: -> void
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

        #: -> void
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

        #: -> void
        def create_relation_group_chain_class
          model.create_class(RelationGroupChainClassName, superclass_name: RelationClassName) do |klass|
            create_group_chain_methods(klass)
            klass.create_type_variable("Elem", type: "type_member", fixed: constant_name)
          end
        end

        #: -> void
        def create_association_relation_group_chain_class
          model.create_class(
            AssociationRelationGroupChainClassName,
            superclass_name: AssociationRelationClassName,
          ) do |klass|
            create_group_chain_methods(klass)
            klass.create_type_variable("Elem", type: "type_member", fixed: constant_name)
          end
        end

        #: (RBI::Scope klass) -> void
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

          klass.create_method(
            "size",
            return_type: "T::Hash[T.untyped, Integer]",
          )

          CALCULATION_METHODS.each do |method_name|
            case method_name
            when :average, :maximum, :minimum
              klass.create_method(
                method_name.to_s,
                parameters: [
                  create_param("column_name", type: "T.any(String, Symbol)"),
                ],
                return_type: "T::Hash[T.untyped, " \
                  "#{method_name == :average ? "T.any(Integer, Float, BigDecimal)" : "T.untyped"}]",
              )
            when :calculate
              klass.create_method(
                "calculate",
                parameters: [
                  create_param("operation", type: "Symbol"),
                  create_param("column_name", type: "T.any(String, Symbol)"),
                ],
                return_type: "T::Hash[T.untyped, T.any(Integer, Float, BigDecimal)]",
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
                return_type: "T::Hash[T.untyped, T.any(Integer, Float, BigDecimal)]",
              )
            end
          end
        end

        #: -> void
        def create_relation_where_chain_class
          model.create_class(RelationWhereChainClassName) do |klass|
            create_where_chain_methods(klass, RelationClassName)
            klass.create_type_variable("Elem", type: "type_member", fixed: constant_name)
          end
        end

        #: -> void
        def create_association_relation_where_chain_class
          model.create_class(AssociationRelationWhereChainClassName) do |klass|
            create_where_chain_methods(klass, AssociationRelationClassName)
            klass.create_type_variable("Elem", type: "type_member", fixed: constant_name)
          end
        end

        #: (RBI::Scope klass, String return_type) -> void
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

        #: -> void
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

        #: (RBI::Scope klass) -> void
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

        #: -> void
        def create_relation_methods
          create_relation_method("all")
          create_unscoped_relation_method

          QUERY_METHODS.each do |method_name|
            case method_name
            when :where
              create_where_relation_method
            when :group
              create_relation_method(
                "group",
                parameters: [
                  create_rest_param("args", type: "T.untyped"),
                  create_block_param("blk", type: "T.untyped"),
                ],
                relation_return_type: RelationGroupChainClassName,
                association_return_type: AssociationRelationGroupChainClassName,
              )
            when :distinct
              create_relation_method(
                method_name.to_s,
                parameters: [create_opt_param("value", type: "T::Boolean", default: "true")],
              )
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
            when :select
              [relation_methods_module, association_relation_methods_module].each do |mod|
                mod.create_method(method_name.to_s) do |method|
                  method.add_rest_param("args")
                  method.add_block_param("blk")

                  method.add_sig do |sig|
                    sig.add_param("args", "T.untyped")
                    sig.return_type = mod == relation_methods_module ? RelationClassName : AssociationRelationClassName
                  end
                  method.add_sig do |sig|
                    sig.add_param("blk", "T.proc.params(record: #{constant_name}).returns(BasicObject)")
                    sig.return_type = "T::Array[#{constant_name}]"
                  end
                end
              end
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

        #: -> void
        def create_association_relation_methods
          # skips insert/upsert methods - these methods' signatures aren't model-specific and don't need to be generated dynamically
          # also skips proxy_association method - it's a private method
          # but there could be other association methods that we need to generate
        end

        #: -> void
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
              id_types = ID_TYPES

              if constant.table_exists?
                primary_key_type = constant.type_for_attribute(constant.primary_key)
                type = Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(primary_key_type)
                type = RBIHelper.as_non_nilable_type(type)

                id_types = ID_TYPES.union([type]) if type != "T.untyped"
              end

              id_types = "T.any(#{id_types.to_a.join(", ")})"
              if constant.try(:composite_primary_key?)
                id_types = "T::Array[#{id_types}]"
              end

              array_type = "T::Array[#{id_types}]"

              common_relation_methods_module.create_method("find") do |method|
                method.add_opt_param("args", "nil")
                method.add_block_param("block")

                method.add_sig do |sig|
                  sig.add_param("args", id_types)
                  sig.return_type = constant_name
                end

                method.add_sig do |sig|
                  sig.add_param("args", array_type)
                  sig.return_type = "T::Enumerable[#{constant_name}]"
                end

                method.add_sig do |sig|
                  sig.add_param("args", "NilClass")
                  sig.add_param("block", "T.proc.params(object: #{constant_name}).void")
                  sig.return_type = as_nilable_type(constant_name)
                end
              end
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
              common_relation_methods_module.create_method(method_name.to_s) do |method|
                method.add_opt_param("limit", "nil")

                method.add_sig do |sig|
                  sig.return_type = as_nilable_type(constant_name)
                end

                method.add_sig do |sig|
                  sig.add_param("limit", "Integer")
                  sig.return_type = "T::Array[#{constant_name}]"
                end
              end
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
                return_type: method_name == :average ? "T.any(Integer, Float, BigDecimal)" : "T.untyped",
              )
            when :calculate
              create_common_method(
                "calculate",
                parameters: [
                  create_param("operation", type: "Symbol"),
                  create_param("column_name", type: "T.any(String, Symbol)"),
                ],
                return_type: "T.any(Integer, Float, BigDecimal)",
              )
            when :count
              common_relation_methods_module.create_method(method_name.to_s) do |method|
                method.add_opt_param("column_name", "nil")
                method.add_block_param("block")

                method.add_sig do |sig|
                  sig.add_param("column_name", "T.nilable(T.any(String, Symbol))")
                  sig.return_type = "Integer"
                end

                method.add_sig do |sig|
                  sig.add_param("column_name", "NilClass")
                  sig.add_param("block", "T.proc.params(object: #{constant_name}).void")
                  sig.return_type = "Integer"
                end
              end
            when :ids
              if constant.table_exists?
                column_type_helper = Tapioca::Dsl::Helpers::ActiveRecordColumnTypeHelper.new(
                  constant,
                  column_type_option: Tapioca::Dsl::Helpers::ActiveRecordColumnTypeHelper::ColumnTypeOption::Persisted,
                )
                primary_key = constant.primary_key
                getter_type, _setter_type = column_type_helper.type_for(primary_key)
                type = getter_type
                create_common_method("ids", return_type: "T::Array[#{type}]")
              else
                create_common_method("ids", return_type: "Array")
              end

            when :pick, :pluck
              create_common_method(
                method_name,
                parameters: [
                  create_rest_param("column_names", type: "T.untyped"),
                ],
                return_type: "T.untyped",
              )
            when :sum
              common_relation_methods_module.create_method(method_name.to_s) do |method|
                method.add_opt_param("initial_value_or_column", "nil")
                method.add_block_param("block")

                method.add_sig do |sig|
                  sig.add_param("initial_value_or_column", "T.untyped")
                  sig.return_type = "T.any(Integer, Float, BigDecimal)"
                end

                method.add_sig(type_params: ["U"]) do |sig|
                  sig.add_param("initial_value_or_column", "T.nilable(T.type_parameter(:U))")
                  sig.add_param("block", "T.proc.params(object: #{constant_name}).returns(T.type_parameter(:U))")
                  sig.return_type = "T.type_parameter(:U)"
                end
              end
            end
          end

          BATCHES_METHODS.each do |method_name|
            block_param, return_type, parameters = batch_method_configs(method_name)
            next if block_param.nil? || return_type.nil? || parameters.nil?

            common_relation_methods_module.create_method(method_name.to_s) do |method|
              parameters.each do |name, (style, _type, default)|
                # The style is always "key", but this is a safeguard to prevent confusing errors in the future.
                raise "Unexpected style #{style} for #{name}" unless style == :key

                method.add_kw_opt_param(name, T.must(default))
              end
              method.add_block_param("block")

              method.add_sig do |sig|
                parameters.each do |name, (_style, type, _default)|
                  sig.add_param(name, type)
                end
                sig.add_param("block", "T.proc.params(object: #{block_param}).void")
                sig.return_type = "void"
              end

              method.add_sig do |sig|
                parameters.each do |name, (_style, type, _default)|
                  sig.add_param(name, type)
                end
                sig.return_type = return_type
              end
            end
          end

          RELATION_METHODS.each do |method_name|
            case method_name
            when :any?, :many?, :none?, :one? # enumerable query methods
              block_type = "T.nilable(T.proc.params(record: #{constant_name}).returns(T.untyped))"
              create_common_method(
                method_name,
                parameters: [
                  create_block_param("block", type: block_type),
                ],
                return_type: "T::Boolean",
              )
            when :find_or_create_by, :find_or_create_by!, :find_or_initialize_by, :create_or_find_by, :create_or_find_by! # find or create methods
              common_relation_methods_module.create_method(method_name.to_s) do |method|
                method.add_param("attributes")
                method.add_block_param("block")

                # `T.untyped` matches `T::Array[T.untyped]` so the array signature
                # must be defined first for Sorbet to pick it, if valid.
                method.add_sig do |sig|
                  sig.add_param("attributes", "T::Array[T.untyped]")
                  sig.add_param("block", "T.nilable(T.proc.params(object: #{constant_name}).void)")
                  sig.return_type = "T::Array[#{constant_name}]"
                end

                method.add_sig do |sig|
                  sig.add_param("attributes", "T.untyped")
                  sig.add_param("block", "T.nilable(T.proc.params(object: #{constant_name}).void)")
                  sig.return_type = constant_name
                end
              end
            when :new, :create, :create!, :build # builder methods
              common_relation_methods_module.create_method(method_name.to_s) do |method|
                method.add_opt_param("attributes", "nil")
                method.add_block_param("block")

                method.add_sig do |sig|
                  sig.add_param("block", "T.nilable(T.proc.params(object: #{constant_name}).void)")
                  sig.return_type = constant_name
                end

                # `T.untyped` matches `T::Array[T.untyped]` so the array signature
                # must be defined first for Sorbet to pick it, if valid.
                method.add_sig do |sig|
                  sig.add_param("attributes", "T::Array[T.untyped]")
                  sig.add_param("block", "T.nilable(T.proc.params(object: #{constant_name}).void)")
                  sig.return_type = "T::Array[#{constant_name}]"
                end

                method.add_sig do |sig|
                  sig.add_param("attributes", "T.untyped")
                  sig.add_param("block", "T.nilable(T.proc.params(object: #{constant_name}).void)")
                  sig.return_type = constant_name
                end
              end
            when :insert_all, :insert_all!, :upsert_all, :insert, :insert!, :upsert # insert methods
              # skip - these methods' signatures aren't model-specific and don't need to be generated dynamically
            when :delete, :destroy
              # For these cases, it is valid to pass the above kind of things, but also:
              # - a model identifier, which can be:
              #   - a numeric id, thus `Integer`
              #   - a string id, thus `String`
              # - a collection of identifiers
              #   - a collection of identifiers, thus `T::Enumerable[T.any(Integer, String)]`
              # which, coupled with the above case, gives us:
              #   `T.any(Model, Integer, String, T::Enumerable[T.any(Model, Integer, String, T::Enumerable[Model])])`

              common_relation_methods_module.create_method(
                method_name.to_s,
                parameters: [
                  create_rest_param(
                    "records",
                    type: "T.any(#{constant_name}, Integer, String" \
                      ", T::Enumerable[T.any(#{constant_name}, Integer, String, T::Enumerable[#{constant_name}])])",
                  ),
                ],
                return_type: method_name == :delete ? "Integer" : "T::Array[#{constant_name}]",
              )
            when :delete_all, :destroy_all
              common_relation_methods_module.create_method(
                method_name.to_s,
                return_type: method_name == :delete_all ? "Integer" : "T::Array[#{constant_name}]",
              )
            when :delete_by, :destroy_by
              common_relation_methods_module.create_method(
                method_name.to_s,
                parameters: [
                  create_param("args", type: "T.untyped"),
                ],
                return_type: method_name == :delete_by ? "Integer" : "T::Array[#{constant_name}]",
              )
            end
          end

          # We are creating `#new` on the class itself since when called as `Model.new`
          # it doesn't allow for an array to be passed. If we kept it as a blanket it
          # would mean the passing any `T.untyped` value to the method would assume
          # the result is `T::Array` which is not the case majority of the time.
          model.create_method("new", class_method: true) do |method|
            method.add_opt_param("attributes", "nil")
            method.add_block_param("block")

            method.add_sig do |sig|
              sig.add_param("attributes", "T.untyped")
              sig.add_param("block", "T.nilable(T.proc.params(object: #{constant_name}).void)")
              sig.return_type = constant_name
            end
          end
        end

        #: (Symbol) -> [String, String, Hash[String, [Symbol, String, String?]]]?
        def batch_method_configs(method_name)
          block_param, return_type = case method_name
          when :find_each
            [constant_name, "T::Enumerator[#{constant_name}]"]
          when :find_in_batches
            ["T::Array[#{constant_name}]", "T::Enumerator[T::Array[#{constant_name}]]"]
          when :in_batches
            [RelationClassName, "::ActiveRecord::Batches::BatchEnumerator"]
          else
            return
          end

          parameters = {}

          ActiveRecord::Batches.instance_method(method_name).parameters.each do |style, name|
            type, default = BATCHES_METHODS_PARAMETERS[name]
            next if type.nil?

            parameters[name.to_s] = [style, type, default]
          end

          [block_param, return_type, parameters]
        end

        #: ((Symbol | String) name, ?parameters: Array[RBI::TypedParam], ?return_type: String?) -> void
        def create_common_method(name, parameters: [], return_type: nil)
          common_relation_methods_module.create_method(
            name.to_s,
            parameters: parameters,
            return_type: return_type || "void",
          )
        end

        #: -> void
        def create_where_relation_method
          relation_methods_module.create_method("where") do |method|
            method.add_rest_param("args")

            method.add_sig do |sig|
              sig.return_type = RelationWhereChainClassName
            end

            method.add_sig do |sig|
              sig.add_param("args", "T.untyped")
              sig.return_type = RelationClassName
            end
          end

          association_relation_methods_module.create_method("where") do |method|
            method.add_rest_param("args")

            method.add_sig do |sig|
              sig.return_type = AssociationRelationWhereChainClassName
            end

            method.add_sig do |sig|
              sig.add_param("args", "T.untyped")
              sig.return_type = AssociationRelationClassName
            end
          end
        end

        #: (
        #|   (Symbol | String) name,
        #|   ?parameters: Array[RBI::TypedParam],
        #|   ?relation_return_type: String,
        #|   ?association_return_type: String
        #| ) -> void
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

        #: -> void
        def create_unscoped_relation_method
          relation_methods_module.create_method("unscoped") do |method|
            method.add_block_param("block")

            method.add_sig do |sig|
              sig.return_type = RelationClassName
            end

            method.add_sig(type_params: ["U"]) do |sig|
              sig.add_param("block", "T.proc.returns(T.type_parameter(:U))")
              sig.return_type = "T.type_parameter(:U)"
            end
          end

          association_relation_methods_module.create_method("unscoped") do |method|
            method.add_block_param("block")

            method.add_sig do |sig|
              sig.return_type = AssociationRelationClassName
            end

            method.add_sig(type_params: ["U"]) do |sig|
              sig.add_param("block", "T.proc.returns(T.type_parameter(:U))")
              sig.return_type = "T.type_parameter(:U)"
            end
          end
        end
      end
    end
  end
end
