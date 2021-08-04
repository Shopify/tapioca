# typed: strict
# frozen_string_literal: true

begin
  require "active_storage"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      class ActiveStorage < Base
        extend T::Sig

        ReflectionType = T.type_alias do
          T.any(::ActiveStorage::Reflection::HasOneAttachedReflection, ::ActiveStorage::Reflection::HasManyAttachedReflection)
        end

        sig { override.params(root: RBI::Tree, constant: T.class_of(::ActiveRecord::Base)).void }
        def decorate(root, constant)
          return if constant.reflections.empty?

          root.create_path(constant) do |model|
            module_name = "GeneratedActiveStorageMethods"

            model.create_module(module_name) do |mod|
              populate_associations(mod, constant)
            end

            model.create_include(module_name)
          end
        end

        sig {override.returns(T::Enumerable[Module])}
        def gather_constants
          ActiveRecord::Base.descendants.reject(&:abstract_class?)
        end

        sig { params(mod: RBI::Scope, constant: T.class_of(::ActiveRecord::Base)).void }
        def populate_associations(mod, constant)
          constant.reflections.each do |association_name, reflection|
            if reflection.collection?
              populate_collection_assoc_getter_setter(mod, constant, association_name, reflection)
            else
              populate_single_assoc_getter_setter(mod, constant, association_name, reflection)
            end
          end
        end

        sig do
          params(
            klass: RBI::Scope,
            constant: T.class_of(::ActiveRecord::Base),
            association_name: T.any(String, Symbol),
            reflection: ReflectionType
          ).void
        end
        def populate_single_assoc_getter_setter(klass, constant, association_name, reflection)
          association_class = type_for(constant, reflection)
          association_type = "T.nilable(#{association_class})"

          klass.create_method(
            association_name.to_s,
            return_type: association_type,
          )
          klass.create_method(
            "#{association_name}=",
            parameters: [create_param("value", type: association_type)],
            return_type: "void"
          )
        end

        sig do
          params(
            klass: RBI::Scope,
            constant: T.class_of(::ActiveRecord::Base),
            association_name: T.any(String, Symbol),
            reflection: ReflectionType
          ).void
        end
        def populate_collection_assoc_getter_setter(klass, constant, association_name, reflection)
          association_class = type_for(constant, reflection)

          klass.create_method(
            association_name.to_s,
            return_type: "void",
          )

          klass.create_method(
            "#{association_name}=",
            parameters: [create_param("value", type: "T::Enumerable[#{association_class}]")],
            return_type: "void",
          )
        end

        sig { params(constant: T.class_of(::ActiveRecord::Base), reflection: ReflectionType).returns(String) }
        def type_for(constant, reflection)
          return "T.untyped" if !constant.table_exists?

          "::#{reflection.klass.name}"
        end


      end
    end
  end
end

