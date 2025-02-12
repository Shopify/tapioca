# typed: strict
# frozen_string_literal: true

return unless defined?(FrozenRecord::Base)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::FrozenRecord` generates RBI files for subclasses of
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
      # this compiler will produce the RBI file `student.rbi` with the following content:
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
      class FrozenRecord < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.all(T.class_of(::FrozenRecord::Base), Extensions::FrozenRecord) } }

        sig { override.void }
        def decorate
          attributes = constant.attributes
          return if attributes.empty?

          root.create_path(constant) do |record|
            module_name = "FrozenRecordAttributeMethods"

            record.create_module(module_name) do |mod|
              attributes.each do |attribute|
                return_type = "T.untyped"
                if constant.respond_to?(:attribute_types)
                  attribute_type = T.let(
                    T.unsafe(constant).attribute_types[attribute],
                    ActiveModel::Type::Value
                  )
                  has_default = T.let(constant.default_attributes.key?(attribute), T::Boolean)
                  return_type = type_for(attribute_type, has_default)
                end

                mod.create_method("#{attribute}?", return_type: "T::Boolean")
                mod.create_method(attribute.to_s, return_type: return_type)
              end
            end

            record.create_include(module_name)

            decorate_scopes(record)
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            descendants_of(::FrozenRecord::Base).reject(&:abstract_class?)
          end
        end

        private

        sig { params(attribute_type_value: ::ActiveModel::Type::Value, has_default: T::Boolean).returns(::String) }
        def type_for(attribute_type_value, has_default)
          type = case attribute_type_value
          when ActiveModel::Type::Boolean
            "T::Boolean"
          when ActiveModel::Type::Date
            "::Date"
          when ActiveModel::Type::DateTime, ActiveModel::Type::Time
            "::DateTime"
          when ActiveModel::Type::Decimal
            "::BigDecimal"
          when ActiveModel::Type::Float
            "::Float"
          when ActiveModel::Type::Integer
            "::Integer"
          when ActiveModel::Type::String
            "::String"
          else
            other_type = attribute_type_value.type
            case other_type
            when :array
              "::Array"
            when :hash
              "::Hash"
            when :symbol
              "::Symbol"
            else
              # we don't want untyped to be wrapped by T.nilable, so just return early
              return "T.untyped"
            end
          end

          has_default ? type : as_nilable_type(type)
        end

        sig { params(record: RBI::Scope).void }
        def decorate_scopes(record)
          scopes = constant.__tapioca_scope_names
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
