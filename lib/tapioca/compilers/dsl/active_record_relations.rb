# typed: strict
# frozen_string_literal: true
begin
  require "active_record"
rescue LoadError
  return
end

require "tapioca/compilers/dsl/helper/active_record_constants"

module Tapioca
  module Compilers
    module Dsl
      class ActiveRecordRelations < Base
        extend T::Sig

        sig do
          override
            .params(root: RBI::Tree, constant: T.class_of(::ActiveRecord::Base))
            .void
        end
        def decorate(root, constant)
          root.create_path(constant) do |model|
            constant_name = T.must(qualified_name_of(constant))
            RelationGenerator.new(model, constant_name).generate
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          ActiveRecord::Base.descendants.reject(&:abstract_class?)
        end

        class RelationGenerator
          extend T::Sig
          include ParamHelper
          include Reflection
          include Helper::ActiveRecordConstants

          sig do
            params(
              model: RBI::Scope,
              constant_name: String
            ).void
          end
          def initialize(model, constant_name)
            @model = model
            @constant_name = constant_name
            @relation_methods_module = T.let(
              model.create_module(RelationMethodsModuleName),
              RBI::Scope
            )
            @association_relation_methods_module = T.let(
              model.create_module(AssociationRelationMethodsModuleName),
              RBI::Scope
            )
            @common_relation_methods_module = T.let(
              model.create_module(CommonRelationMethodsModuleName),
              RBI::Scope
            )
          end

          sig { void }
          def generate
            create_classes_and_includes
            create_common_methods
            create_relation_methods
            create_association_relation_methods
          end

          ASSOCIATION_METHODS = T.let(
            ::ActiveRecord::AssociationRelation.instance_methods -
              ::ActiveRecord::Relation.instance_methods,
            T::Array[Symbol]
          )
          COLLECTION_PROXY_METHODS = T.let(
            ::ActiveRecord::Associations::CollectionProxy.instance_methods -
              ::ActiveRecord::AssociationRelation.instance_methods,
            T::Array[Symbol]
          )

          QUERY_METHODS = T.let(begin
            # Grab all Query methods
            query_methods = ActiveRecord::QueryMethods.instance_methods(false)
            # Grab all Spawn methods
            query_methods |= ActiveRecord::SpawnMethods.instance_methods(false)
            # Remove the ones we know are private API
            query_methods -= [:arel, :build_subquery, :construct_join_dependency, :extensions, :spawn]
            # Remove the methods that ...
            query_methods
              .grep_v(/_clause$/) # end with "_clause"
              .grep_v(/_values?$/) # end with "_value" or "_values"
              .grep_v(/=$/) # end with "=""
              .grep_v(/(?<!uniq)!$/) # end with "!" except for "uniq!"
          end, T::Array[Symbol])
          FINDER_METHODS = T.let(ActiveRecord::FinderMethods.instance_methods(false), T::Array[Symbol])
          CALCULATION_METHODS = T.let(ActiveRecord::Calculations.instance_methods(false), T::Array[Symbol])
          ENUMERABLE_QUERY_METHODS = T.let([:any?, :many?, :none?, :one?], T::Array[Symbol])
          FIND_OR_CREATE_METHODS = T.let(
            [:find_or_create_by, :find_or_create_by!, :find_or_initialize_by, :create_or_find_by, :create_or_find_by!],
            T::Array[Symbol]
          )
          BUILDER_METHODS = T.let([:new, :build, :create, :create!], T::Array[Symbol])

          private

          sig { returns(RBI::Scope) }
          attr_reader :model

          sig { returns(String) }
          attr_reader :constant_name

          sig { void }
          def create_classes_and_includes
            model.create_extend(CommonRelationMethodsModuleName)
            # The model always extends the generated relation module
            model.create_extend(RelationMethodsModuleName)
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
              klass.create_constant("Elem", value: "type_member(fixed: #{constant_name})")

              klass.create_method("to_ary", return_type: "T::Array[#{constant_name}]")
            end
          end

          sig { void }
          def create_association_relation_class
            superclass = "::ActiveRecord::AssociationRelation"

            # Association subclasses include the generated association relation module
            model.create_class(AssociationRelationClassName, superclass_name: superclass) do |klass|
              klass.create_include(CommonRelationMethodsModuleName)
              klass.create_include(AssociationRelationMethodsModuleName)
              klass.create_constant("Elem", value: "type_member(fixed: #{constant_name})")

              klass.create_method("to_ary", return_type: "T::Array[#{constant_name}]")
            end
          end

          sig { void }
          def create_collection_proxy_class
            superclass = "::ActiveRecord::Associations::CollectionProxy"

            # The relation subclass includes the generated association relation module
            model.create_class(AssociationsCollectionProxyClassName, superclass_name: superclass) do |klass|
              klass.create_include(CommonRelationMethodsModuleName)
              klass.create_include(AssociationRelationMethodsModuleName)
              klass.create_constant("Elem", value: "type_member(fixed: #{constant_name})")

              klass.create_method("to_ary", return_type: "T::Array[#{constant_name}]")
              create_collection_proxy_methods(klass)
            end
          end

          sig { params(klass: RBI::Scope).void }
          def create_collection_proxy_methods(klass)
            const_collection = "T.any(" + [
              constant_name,
              "T::Array[#{constant_name}]",
              "T::Array[#{AssociationsCollectionProxyClassName}]",
            ].join(", ") + ")"

            COLLECTION_PROXY_METHODS.each do |method_name|
              case method_name
              when :<<, :append, :concat, :prepend, :push
                klass.create_method(
                  method_name.to_s,
                  parameters: [
                    create_rest_param("records", type: const_collection),
                  ],
                  return_type: AssociationsCollectionProxyClassName
                )
              when :clear
                klass.create_method(
                  method_name.to_s,
                  return_type: AssociationsCollectionProxyClassName
                )
              when :delete, :destroy
                klass.create_method(
                  method_name.to_s,
                  parameters: [
                    create_rest_param("records", type: const_collection),
                  ],
                  return_type: "T::Array[#{constant_name}]"
                )
              when :load_target
                klass.create_method(
                  method_name.to_s,
                  return_type: "T::Array[#{constant_name}]"
                )
              when :replace
                klass.create_method(
                  method_name.to_s,
                  parameters: [
                    create_param("other_array", type: const_collection),
                  ],
                  return_type: "T::Array[#{constant_name}]"
                )
              when :reset_scope
                # skip
              when :scope
                klass.create_method(
                  method_name.to_s,
                  return_type: AssociationRelationClassName
                )
              when :target
                klass.create_method(
                  method_name.to_s,
                  return_type: "T::Array[#{constant_name}]"
                )
              end
            end
          end

          sig { void }
          def create_relation_methods
            create_relation_method("all")
            create_relation_method(
              "not",
              parameters: [
                create_param("opts", type: "T.untyped"),
                create_rest_param("rest", type: "T.untyped"),
              ]
            )

            QUERY_METHODS.each do |method_name|
              create_relation_method(
                method_name,
                parameters: [
                  create_rest_param("args", type: "T.untyped"),
                  create_block_param("blk", type: "T.untyped"),
                ]
              )
            end
          end

          sig { void }
          def create_association_relation_methods
            returning_type = "T.nilable(T.any(T::Array[Symbol], FalseClass)"
            unique_by_type = "T.nilable(T.any(T::Array[Symbol], Symbol))"

            ASSOCIATION_METHODS.each do |method_name|
              case method_name
              when :insert_all, :insert_all!, :upsert_all
                parameters = [
                  create_param("attributes", type: "T::Array[Hash]"),
                  create_kw_opt_param("returning", type: returning_type, default: "nil"),
                ]

                # Bang methods don't have the `unique_by` parameter
                unless method_name.end_with?("!")
                  parameters << create_kw_opt_param("unique_by", type: unique_by_type, default: "nil")
                end

                @association_relation_methods_module.create_method(
                  method_name.to_s,
                  parameters: parameters,
                  return_type: "ActiveRecord::Result"
                )
              when :insert, :insert!, :upsert
                parameters = [
                  create_param("attributes", type: "Hash"),
                  create_kw_opt_param("returning", type: returning_type, default: "nil"),
                ]

                # Bang methods don't have the `unique_by` parameter
                unless method_name.end_with?("!")
                  parameters << create_kw_opt_param("unique_by", type: unique_by_type, default: "nil")
                end

                @association_relation_methods_module.create_method(
                  method_name.to_s,
                  parameters: parameters,
                  return_type: "ActiveRecord::Result"
                )
              when :proxy_association
                # skip - private method
              end
            end
          end

          sig { void }
          def create_common_methods
            create_common_method("destroy_all", return_type: "T::Array[#{constant_name}]")

            FINDER_METHODS.each do |method_name|
              case method_name
              when :exists?
                create_common_method(
                  "exists?",
                  parameters: [
                    create_opt_param("conditions", type: "T.untyped", default: ":none"),
                  ],
                  return_type: "T::Boolean"
                )
              when :include?, :member?
                create_common_method(
                  method_name,
                  parameters: [
                    create_param("record", type: "T.untyped"),
                  ],
                  return_type: "T::Boolean"
                )
              when :find, :find_by!
                create_common_method(
                  "find",
                  parameters: [
                    create_rest_param("args", type: "T.untyped"),
                  ],
                  return_type: "T.untyped"
                )
              when :find_by
                create_common_method(
                  "find_by",
                  parameters: [
                    create_rest_param("args", type: "T.untyped"),
                  ],
                  return_type: "T.nilable(#{constant_name})"
                )
              when :first, :last, :take
                create_common_method(
                  method_name,
                  parameters: [
                    create_opt_param("limit", type: "T.untyped", default: "nil"),
                  ],
                  return_type: "T.untyped"
                )
              when :raise_record_not_found_exception!
                # skip
              else
                return_type = if method_name.end_with?("!")
                  constant_name
                else
                  "T.nilable(#{constant_name})"
                end

                create_common_method(
                  method_name,
                  return_type: return_type
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
                  return_type: "T.untyped"
                )
              when :calculate
                create_common_method(
                  "calculate",
                  parameters: [
                    create_param("operation", type: "Symbol"),
                    create_param("column_name", type: "T.any(String, Symbol)"),
                  ],
                  return_type: "T.untyped"
                )
              when :count
                create_common_method(
                  "count",
                  parameters: [
                    create_opt_param("column_name", type: "T.untyped", default: "nil"),
                  ],
                  return_type: "T.untyped"
                )
              when :ids
                create_common_method("ids", return_type: "Array")
              when :pick, :pluck
                create_common_method(
                  method_name,
                  parameters: [
                    create_rest_param("column_names", type: "T.untyped"),
                  ],
                  return_type: "T.untyped"
                )
              when :sum
                create_common_method(
                  "sum",
                  parameters: [
                    create_opt_param("column_name", type: "T.nilable(T.any(String, Symbol))", default: "nil"),
                    create_block_param("block", type: "T.nilable(T.proc.params(record: T.untyped).returns(T.untyped))"),
                  ],
                  return_type: "T.untyped"
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
                return_type: "T::Boolean"
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
                return_type: constant_name
              )
            end

            BUILDER_METHODS.each do |method_name|
              create_common_method(
                method_name,
                parameters: [
                  create_opt_param("attributes", type: "T.nilable(T.any(::Hash, T::Array[::Hash]))", default: "nil"),
                  create_block_param("block", type: "T.nilable(T.proc.params(object: #{constant_name}).void)"),
                ],
                return_type: constant_name
              )
            end
          end

          sig do
            params(
              name: T.any(Symbol, String),
              parameters: T::Array[RBI::TypedParam],
              return_type: T.nilable(String)
            ).void
          end
          def create_common_method(name, parameters: [], return_type: nil)
            @common_relation_methods_module.create_method(
              name.to_s,
              parameters: parameters,
              return_type: return_type || "void"
            )
          end

          sig { params(name: T.any(Symbol, String), parameters: T::Array[RBI::TypedParam]).void }
          def create_relation_method(name, parameters: [])
            @relation_methods_module.create_method(
              name.to_s,
              parameters: parameters,
              return_type: RelationClassName
            )
            @association_relation_methods_module.create_method(
              name.to_s,
              parameters: parameters,
              return_type: AssociationRelationClassName
            )
          end
        end
      end
    end
  end
end
