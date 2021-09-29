# typed: strict
# frozen_string_literal: true
begin
  require "active_record"
rescue LoadError
  return
end

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
            RelationGenerator.new(self, model, constant).generate
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

          sig do
            params(
              compiler: Base,
              model: RBI::Scope,
              constant: T.class_of(::ActiveRecord::Base)
            ).void
          end
          def initialize(compiler, model, constant)
            @compiler = compiler
            @model = model
            @constant = constant
            @constant_name = T.let(T.must(qualified_name_of(constant)), String)
            @relation_methods_module_name = T.let("GeneratedRelationMethods", String)
            @association_relation_methods_module_name = T.let("GeneratedAssociationRelationMethods", String)
            @common_relation_methods_module_name = T.let("CommonRelationMethods", String)
            @relation_class_name = T.let("PrivateRelation", String)
            @association_relation_class_name = T.let("PrivateAssociationRelation", String)
            @associations_collection_proxy_class_name = T.let("PrivateCollectionProxy", String)
            @relation_methods_module = T.let(
              model.create_module(@relation_methods_module_name),
              RBI::Scope
            )
            @association_relation_methods_module = T.let(
              model.create_module(@association_relation_methods_module_name),
              RBI::Scope
            )
            @common_relation_methods_module = T.let(
              model.create_module(@common_relation_methods_module_name),
              RBI::Scope
            )
          end

          sig { void }
          def generate
            create_classes_and_includes
            create_common_methods
            create_relation_methods
          end

          private

          sig { returns(RBI::Scope) }
          attr_reader :model

          sig { void }
          def create_classes_and_includes
            model.create_extend(@common_relation_methods_module_name)
            # The model always extends the generated relation module
            model.create_extend(@relation_methods_module_name)
            create_relation_class
            create_association_relation_class
            create_collection_proxy_class
          end

          sig { void }
          def create_relation_class
            superclass = "::ActiveRecord::Relation"

            # The relation subclass includes the generated relation module
            model.create_class(@relation_class_name, superclass_name: superclass) do |klass|
              klass.create_include(@common_relation_methods_module_name)
              klass.create_include(@relation_methods_module_name)
              klass.create_constant("Elem", value: "type_member(fixed: #{@constant_name})")

              klass.create_method("to_ary", parameters: [], return_type: "T::Array[#{@constant_name}]")
            end
          end

          sig { void }
          def create_association_relation_class
            superclass = "::ActiveRecord::AssociationRelation"

            # Association subclasses include the generated association relation module
            model.create_class(@association_relation_class_name, superclass_name: superclass) do |klass|
              klass.create_include(@common_relation_methods_module_name)
              klass.create_include(@association_relation_methods_module_name)
              klass.create_constant("Elem", value: "type_member(fixed: #{@constant_name})")

              klass.create_method("to_ary", parameters: [], return_type: "T::Array[#{@constant_name}]")
              create_association_relation_methods(klass)
            end
          end

          sig { void }
          def create_collection_proxy_class
            superclass = "::ActiveRecord::Associations::CollectionProxy"

            # The relation subclass includes the generated association relation module
            model.create_class(@associations_collection_proxy_class_name, superclass_name: superclass) do |klass|
              klass.create_include(@common_relation_methods_module_name)
              klass.create_include(@association_relation_methods_module_name)
              klass.create_constant("Elem", value: "type_member(fixed: #{@constant_name})")

              klass.create_method("to_ary", parameters: [], return_type: "T::Array[#{@constant_name}]")
              create_association_relation_methods(klass)
              create_collection_proxy_methods(klass)
            end
          end

          sig { params(klass: RBI::Scope).void }
          def create_association_relation_methods(klass)
            association_methods = ::ActiveRecord::AssociationRelation.instance_methods -
              ::ActiveRecord::Relation.instance_methods

            association_methods.each do |method_name|
              case method_name
              when :insert_all, :insert_all!, :upsert_all
                klass.create_method(
                  method_name.to_s,
                  parameters: [
                    create_param("attributes", type: "T::Array[Hash]"),
                    create_kw_opt_param("returning", type: "T::Array[Symbol]", default: "nil"),
                    create_kw_opt_param("unique_by", type: "T.any(T::Array[Symbol], Symbol)", default: "nil"),
                  ],
                  return_type: "ActiveRecord::Result"
                )
              when :insert_all!
                klass.create_method(
                  method_name.to_s,
                  parameters: [
                    create_param("attributes", type: "T::Array[Hash]"),
                    create_kw_opt_param("returning", type: "T::Array[Symbol]", default: "nil"),
                  ],
                  return_type: "ActiveRecord::Result"
                )
              when :insert, :insert!, :upsert
                klass.create_method(
                  method_name.to_s,
                  parameters: [
                    create_param("attributes", type: "Hash"),
                    create_kw_opt_param("returning", type: "T::Array[Symbol]", default: "nil"),
                    create_kw_opt_param("unique_by", type: "T.any(T::Array[Symbol], Symbol)", default: "nil"),
                  ],
                  return_type: "ActiveRecord::Result"
                )
              when :insert, :insert!, :upsert
                klass.create_method(
                  method_name.to_s,
                  parameters: [
                    create_param("attributes", type: "Hash"),
                    create_kw_opt_param("returning", type: "T::Array[Symbol]", default: "nil"),
                  ],
                  return_type: "ActiveRecord::Result"
                )
              when :proxy_association
                # skip - private method
              end
            end
          end

          sig { params(klass: RBI::Scope).void }
          def create_collection_proxy_methods(klass)
            const_collection = "T.any(" + [
              @constant_name,
              "T::Array[#{@constant_name}]",
              "T::Array[#{@associations_collection_proxy_class_name}]",
            ].join(", ") + ")"

            collection_proxy_methods = ::ActiveRecord::Associations::CollectionProxy.instance_methods -
              ::ActiveRecord::AssociationRelation.instance_methods

            collection_proxy_methods.each do |method_name|
              case method_name
              when :<<, :append, :concat, :prepend, :push
                klass.create_method(
                  method_name.to_s,
                  parameters: [
                    create_rest_param("records", type: const_collection),
                  ],
                  return_type: @associations_collection_proxy_class_name
                )
              when :clear
                klass.create_method(
                  "clear",
                  parameters: [],
                  return_type: @associations_collection_proxy_class_name
                )
              when :delete, :destroy
                klass.create_method(
                  method_name.to_s,
                  parameters: [
                    create_rest_param("records", type: const_collection),
                  ],
                  return_type: "T::Array[#{@constant_name}]"
                )
              when :load_target
                klass.create_method(
                  method_name.to_s,
                  parameters: [],
                  return_type: "T::Array[#{@constant_name}]"
                )
              when :replace
                klass.create_method(
                  method_name.to_s,
                  parameters: [
                    create_param("other_array", type: const_collection),
                  ],
                  return_type: "void"
                )
              when :reset_scope
                # skip
              when :scope
                klass.create_method(
                  method_name.to_s,
                  parameters: [],
                  return_type: @association_relation_class_name
                )
              when :target
                klass.create_method(
                  method_name.to_s,
                  parameters: [],
                  return_type: "T::Array[#{@constant_name}]"
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

            # Grab all Query methods
            query_methods = ActiveRecord::QueryMethods.instance_methods(false)
            # Grab all Spawn methods
            query_methods |= ActiveRecord::SpawnMethods.instance_methods(false)
            # Remove the ones we know are private API
            query_methods -= [:arel, :build_subquery, :construct_join_dependency, :extensions, :spawn]
            # Remove the methods that ...
            query_methods = query_methods
              .grep_v(/_clause$/) # end with "_clause"
              .grep_v(/_values?$/) # end with "_value" or "_values"
              .grep_v(/=$/) # end with "=""
              .grep_v(/(?<!uniq)!$/) # end with "!" except for "uniq!"

            query_methods.each do |method_name|
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
          def create_common_methods
            create_common_method("destroy_all", return_type: "T::Array[#{@constant_name}]")

            ActiveRecord::FinderMethods.instance_methods(false).each do |method_name|
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
                  return_type: "T.nilable(#{@constant_name})"
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
                create_common_method(
                  method_name,
                  return_type: method_name.to_s.end_with?("!") ? @constant_name : "T.nilable(#{@constant_name})"
                )
              end
            end

            ActiveRecord::Calculations.instance_methods(false).each do |method_name|
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

            enumerable_query_methods = [:any?, :many?, :none?, :one?]
            enumerable_query_methods.each do |method_name|
              block_type = "T.nilable(T.proc.params(record: #{@constant_name}).returns(T.untyped))"
              create_common_method(
                method_name,
                parameters: [
                  create_block_param("block", type: block_type),
                ],
                return_type: "T::Boolean"
              )
            end

            find_or_create_methods = [:find_or_create_by, :find_or_create_by!, :find_or_initialize_by,
                                      :create_or_find_by, :create_or_find_by!]

            find_or_create_methods.each do |method_name|
              block_type = "T.nilable(T.proc.params(object: #{@constant_name}).void)"
              create_common_method(
                method_name,
                parameters: [
                  create_param("attributes", type: "T.untyped"),
                  create_block_param("block", type: block_type),
                ],
                return_type: @constant_name
              )
            end

            [:new, :build, :create, :create!].each do |method_name|
              create_common_method(
                method_name,
                parameters: [
                  create_opt_param("attributes", type: "T.nilable(T.any(::Hash, T::Array[::Hash]))", default: "nil"),
                  create_block_param("block", type: "T.nilable(T.proc.params(object: #{@constant_name}).void)"),
                ],
                return_type: @constant_name
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
              return_type: @relation_class_name
            )
            @association_relation_methods_module.create_method(
              name.to_s,
              parameters: parameters,
              return_type: @association_relation_class_name
            )
          end
        end
      end
    end
  end
end
