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

          column = @constant.columns_hash[column_name]
          column_type = @constant.attribute_types[column_name]
          getter_type = type_for_activerecord_value(column_type)
          setter_type =
            case column_type
            when ActiveRecord::Enum::EnumType
              enum_setter_type(column_type)
            else
              getter_type
            end

          if @column_type_option.persisted? && !column&.null
            [getter_type, setter_type]
          else
            getter_type = as_nilable_type(getter_type) unless not_nilable_serialized_column?(column_type)
            [getter_type, as_nilable_type(setter_type)]
          end
        end

        sig { params(column_type: T.untyped).returns(String) }
        def type_for_activerecord_value(column_type)
          case column_type
          when defined?(MoneyColumn) && MoneyColumn::ActiveRecordType
            "::Money"
          when ActiveRecord::Type::Integer
            "::Integer"
          when defined?(ActiveRecord::Encryption) && ActiveRecord::Encryption::EncryptedAttributeType
            # Reflect to see if `ActiveModel::Type::Value` is being used first.
            getter_type = Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(column_type)
            return getter_type unless getter_type == "T.untyped"

            # Otherwise fallback to String as `ActiveRecord::Encryption::EncryptedAttributeType` inherits from
            # `ActiveRecord::Type::Text` which inherits from `ActiveModel::Type::String`.
            "::String"
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
          when ActiveRecord::Type::Serialized
            serialized_column_type(column_type)
          when defined?(ActiveRecord::Normalization::NormalizedValueType) &&
            ActiveRecord::Normalization::NormalizedValueType
            type_for_activerecord_value(column_type.cast_type)
          when defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Uuid) &&
            ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Uuid
            "::String"
          when defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Cidr) &&
            ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Cidr
            "::IPAddr"
          when defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Hstore) &&
            ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Hstore
            "T::Hash[::String, ::String]"
          when defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array) &&
            ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array
            "T::Array[#{type_for_activerecord_value(column_type.subtype)}]"
          else
            ActiveModelTypeHelper.type_for(column_type)
          end
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
      end
    end
  end
end
