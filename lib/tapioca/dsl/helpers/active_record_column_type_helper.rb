# typed: strict
# frozen_string_literal: true

require "tapioca/dsl/helpers/active_model_type_helper"

module Tapioca
  module Dsl
    module Helpers
      class ActiveRecordColumnTypeHelper
        extend T::Sig
        include RBIHelper

        class ColumnTypeOption < T::Enum
          extend T::Sig

          enums do
            Untyped = new("untyped")
            Nilable = new("nilable")
            Persisted = new("persisted")
          end

          class << self
            extend T::Sig

            sig do
              params(
                options: T::Hash[String, T.untyped],
                block: T.proc.params(value: String, default_column_type_option: ColumnTypeOption).void,
              ).returns(ColumnTypeOption)
            end
            def from_options(options, &block)
              column_type_option = Persisted
              value = options["ActiveRecordColumnTypes"]

              if value
                if has_serialized?(value)
                  column_type_option = from_serialized(value)
                else
                  block.call(value, column_type_option)
                end
              end

              column_type_option
            end
          end

          sig { returns(T::Boolean) }
          def persisted?
            self == ColumnTypeOption::Persisted
          end

          sig { returns(T::Boolean) }
          def nilable?
            self == ColumnTypeOption::Nilable
          end

          sig { returns(T::Boolean) }
          def untyped?
            self == ColumnTypeOption::Untyped
          end
        end

        sig do
          params(
            constant: T.class_of(ActiveRecord::Base),
            column_type_option: ColumnTypeOption,
          ).void
        end
        def initialize(constant, column_type_option: ColumnTypeOption::Persisted)
          @constant = constant
          @column_type_option = column_type_option
        end

        sig do
          params(
            attribute_name: String,
            column_name: String,
          ).returns([String, String])
        end
        def type_for(attribute_name, column_name = attribute_name)
          return id_type if attribute_name == "id"

          column_type_for(column_name)
        end

        private

        sig { returns([String, String]) }
        def id_type
          if @constant.respond_to?(:composite_primary_key?) && T.unsafe(@constant).composite_primary_key?
            @constant.primary_key.map do |column|
              column_type_for(column)
            end.map do |tuple|
              "[#{tuple.join(", ")}]"
            end
          else
            column_type_for(@constant.primary_key)
          end
        end

        sig { params(column_name: String).returns([String, String]) }
        def column_type_for(column_name)
          return ["T.untyped", "T.untyped"] if @column_type_option.untyped?

          nilable_column = !has_non_null_database_constraint?(column_name) &&
            !has_unconditional_presence_validator?(column_name)

          column_type = @constant.attribute_types[column_name]
          getter_type = type_for_activerecord_value(column_type, column_nullability: nilable_column)
          setter_type =
            case column_type
            when ActiveRecord::Enum::EnumType
              enum_setter_type(column_type)
            else
              getter_type
            end

          if @column_type_option.persisted? && (virtual_attribute?(column_name) || !nilable_column)
            [getter_type, setter_type]
          else
            getter_type = as_nilable_type(getter_type) unless not_nilable_serialized_column?(column_type)
            [getter_type, as_nilable_type(setter_type)]
          end
        end

        sig { params(column_type: T.untyped, column_nullability: T::Boolean).returns(String) }
        def type_for_activerecord_value(column_type, column_nullability:)
          case column_type
          when ->(type) { defined?(MoneyColumn) && MoneyColumn::ActiveRecordType === type }
            "::Money"
          when ActiveRecord::Type::Integer
            "::Integer"
          when ->(type) {
            defined?(ActiveRecord::Encryption) && ActiveRecord::Encryption::EncryptedAttributeType === type
          }
            # Reflect to see if `ActiveModel::Type::Value` is being used first.
            getter_type = Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(column_type)

            # Fallback to String as `ActiveRecord::Encryption::EncryptedAttributeType` inherits from
            # `ActiveRecord::Type::Text` which inherits from `ActiveModel::Type::String`.
            return "::String" if getter_type == "T.untyped"

            as_non_nilable_if_persisted_and_not_nullable(getter_type, column_nullability:)
          when ActiveRecord::Type::String
            "::String"
          when ActiveRecord::Type::Date
            "::Date"
          when ActiveRecord::Type::Decimal
            "::BigDecimal"
          when ActiveRecord::Type::Float
            "::Float"
          when ActiveRecord::Type::Boolean
            "T::Boolean"
          when ActiveRecord::Type::DateTime, ActiveRecord::Type::Time
            "::Time"
          when ActiveRecord::AttributeMethods::TimeZoneConversion::TimeZoneConverter
            "::ActiveSupport::TimeWithZone"
          when ActiveRecord::Enum::EnumType
            "::String"
          when ActiveRecord::Type::Binary
            "::String"
          when ActiveRecord::Type::Serialized
            serialized_column_type(column_type)
          when ->(type) {
                 defined?(ActiveRecord::Normalization::NormalizedValueType) &&
                   ActiveRecord::Normalization::NormalizedValueType === type
               }
            type_for_activerecord_value(column_type.cast_type, column_nullability:)
          when ->(type) {
                 defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Uuid) &&
                   ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Uuid === type
               }
            "::String"
          when ->(type) {
                 defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Cidr) &&
                   ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Cidr === type
               }
            "::IPAddr"
          when ->(type) {
                 defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Hstore) &&
                   ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Hstore === type
               }
            "T::Hash[::String, ::String]"
          when ->(type) {
                 defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array) &&
                   ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array === type
               }
            "T::Array[#{type_for_activerecord_value(column_type.subtype, column_nullability:)}]"
          else
            as_non_nilable_if_persisted_and_not_nullable(
              ActiveModelTypeHelper.type_for(column_type),
              column_nullability: column_nullability,
            )
          end
        end

        sig { params(base_type: String, column_nullability: T::Boolean).returns(String) }
        def as_non_nilable_if_persisted_and_not_nullable(base_type, column_nullability:)
          # It's possible that when ActiveModel::Type::Value is used, the signature being reflected on in
          # ActiveModelTypeHelper.type_for(type_value) may say the type can be nilable. However, if the type is
          # persisted and the column is not nullable, we can assume it's not nilable.
          return as_non_nilable_type(base_type) if @column_type_option.persisted? && !column_nullability

          base_type
        end

        sig { params(column_type: ActiveRecord::Enum::EnumType).returns(String) }
        def enum_setter_type(column_type)
          # In Rails < 7 this method is private. When support for that is dropped we can call the method directly
          case column_type.send(:subtype)
          when ActiveRecord::Type::Integer
            "T.any(::String, ::Symbol, ::Integer)"
          else
            "T.any(::String, ::Symbol)"
          end
        end

        sig { params(column_type: ActiveRecord::Type::Serialized).returns(String) }
        def serialized_column_type(column_type)
          case column_type.coder
          when ActiveRecord::Coders::YAMLColumn
            case column_type.coder.object_class
            when Array.singleton_class
              "T::Array[T.untyped]"
            when Hash.singleton_class
              "T::Hash[T.untyped, T.untyped]"
            else
              "T.untyped"
            end
          else
            "T.untyped"
          end
        end

        sig { params(column_type: T.untyped).returns(T::Boolean) }
        def not_nilable_serialized_column?(column_type)
          return false unless column_type.is_a?(ActiveRecord::Type::Serialized)
          return false unless column_type.coder.is_a?(ActiveRecord::Coders::YAMLColumn)

          [Array.singleton_class, Hash.singleton_class].include?(column_type.coder.object_class.singleton_class)
        end

        sig { params(column_name: String).returns(T::Boolean) }
        def virtual_attribute?(column_name)
          @constant.columns_hash[column_name].nil?
        end

        sig { params(column_name: String).returns(T::Boolean) }
        def has_non_null_database_constraint?(column_name)
          column = @constant.columns_hash[column_name]
          return false if column.nil?

          !column.null
        end

        sig { params(column_name: String).returns(T::Boolean) }
        def has_unconditional_presence_validator?(column_name)
          return false unless @constant.respond_to?(:validators_on)

          @constant.validators_on(column_name).any? do |validator|
            next false unless validator.is_a?(ActiveRecord::Validations::PresenceValidator)

            !validator.options.key?(:if) && !validator.options.key?(:unless) && !validator.options.key?(:on)
          end
        end
      end
    end
  end
end
