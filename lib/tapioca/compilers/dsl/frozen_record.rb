# typed: strict
# frozen_string_literal: true

begin
  require "frozen_record"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::Dsl::FrozenRecord` generates RBI files for subclasses of
      # [`FrozenRecord::Base`](https://github.com/byroot/frozen_record).
      #
      # For example, with the following FrozenRecord class:
      #
      # ~~~rb
      # # student.rb
      # class Student < FrozenRecord::Base
      # end
      # ~~~
      #
      # and the following YAML file:
      #
      # ~~~ yaml
      # # students.yml
      # - id: 1
      #   first_name: John
      #   last_name: Smith
      # - id: 2
      #   first_name: Dan
      #   last_name:  Lord
      # ~~~
      #
      # this generator will produce the RBI file `student.rbi` with the following content:
      #
      # ~~~rbi
      # # Student.rbi
      # # typed: strong
      # class Student
      #   include FrozenRecordAttributeMethods
      #
      #   module FrozenRecordAttributeMethods
      #     sig { returns(T.untyped) }
      #     def first_name; end
      #
      #     sig { returns(T::Boolean) }
      #     def first_name?; end
      #
      #     sig { returns(T.untyped) }
      #     def id; end
      #
      #     sig { returns(T::Boolean) }
      #     def id?; end
      #
      #     sig { returns(T.untyped) }
      #     def last_name; end
      #
      #     sig { returns(T::Boolean) }
      #     def last_name?; end
      #   end
      # end
      # ~~~
      class FrozenRecord < Base
        extend T::Sig

        sig { override.params(root: RBI::Tree, constant: T.class_of(::FrozenRecord::Base)).void }
        def decorate(root, constant)
          attributes = constant.attributes
          return if attributes.empty?

          root.create_path(constant) do |record|
            module_name = "FrozenRecordAttributeMethods"

            record.create_module(module_name) do |mod|
              attributes.each do |attribute|
                mod.create_method("#{attribute}?", return_type: "T::Boolean")
                mod.create_method(attribute.to_s, return_type: "T.untyped")
              end
            end

            record.create_include(module_name)

            decorate_scopes(constant, record)
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          descendants_of(::FrozenRecord::Base).reject(&:abstract_class?)
        end

        private

        sig { params(constant: T.class_of(::FrozenRecord::Base), record: RBI::Scope).void }
        def decorate_scopes(constant, record)
          scopes = T.unsafe(constant).__tapioca_scope_names
          return if scopes.nil?

          module_name = "GeneratedRelationMethods"

          record.create_module(module_name) do |mod|
            scopes.each do |name|
              generate_scope_method(name.to_s, mod)
            end
          end

          record.create_extend(module_name)
        end

        sig do
          params(
            scope_method: String,
            mod: RBI::Scope,
          ).void
        end
        def generate_scope_method(scope_method, mod)
          mod.create_method(
            scope_method,
            parameters: [
              create_rest_param("args", type: "T.untyped"),
              create_block_param("blk", type: "T.untyped"),
            ],
            return_type: "T.untyped",
          )
        end
      end
    end
  end
end
