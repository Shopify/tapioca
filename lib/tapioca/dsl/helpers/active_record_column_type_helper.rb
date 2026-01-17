# typed: strict
# frozen_string_literal: true

require "tapioca/dsl/helpers/active_model_type_helper"

module Tapioca
  module Dsl
    module Helpers
      class ActiveRecordColumnTypeHelper
        include RBIHelper

        class ColumnTypeOption < T::Enum
          enums do
            Untyped = new("untyped")
            Nilable = new("nilable")
            Persisted = new("persisted")
          end

          class << self
            #: (
            #|   Hash[String, untyped] options,
            #| ) { (String value, ColumnTypeOption default_column_type_option) -> void } -> ColumnTypeOption
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

          #: -> bool
          def persisted?
            self == ColumnTypeOption::Persisted
          end

          #: -> bool
          def nilable?
            self == ColumnTypeOption::Nilable
          end

          #: -> bool
          def untyped?
            self == ColumnTypeOption::Untyped
          end
        end

        #: (singleton(ActiveRecord::Base) constant, ?column_type_option: ColumnTypeOption) -> void
        def initialize(constant, column_type_option: ColumnTypeOption::Persisted)
          @constant = constant
          @column_type_option = column_type_option
        end

        #: (String attribute_name, ?String column_name) -> [RBI::Type, RBI::Type]
        def type_for(attribute_name, column_name = attribute_name)
          return id_type if attribute_name == "id"

          column_type_for(column_name)
        end

        private

        #: -> [RBI::Type, RBI::Type]
        def id_type
          if @constant.respond_to?(:composite_primary_key?) && T.unsafe(@constant).composite_primary_key?
            primary_key_columns = @constant.primary_key

            getters = []
            setters = []

            primary_key_columns.each do |column|
              getter, setter = column_type_for(column)
              getters << getter
              setters << setter
            end

            [RBI::Type.tuple(*getters), RBI::Type.tuple(*setters)]
          else
            column_type_for(@constant.primary_key)
          end
        end

        #: (String? column_name) -> [RBI::Type, RBI::Type]
        def column_type_for(column_name)
          return [RBI::Type.untyped, RBI::Type.untyped] if @column_type_option.untyped?

          column = @constant.columns_hash[column_name]
          column_type = @constant.attribute_types[column_name]
          getter_type = type_for_activerecord_value(column_type, column_nullability: !!column&.null)
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
            getter_type = getter_type.nilable unless not_nilable_serialized_column?(column_type)
            [getter_type, setter_type.nilable]
          end
        end

        #: (untyped column_type, column_nullability: bool) -> RBI::Type
        def type_for_activerecord_value(column_type, column_nullability:)
          case column_type
          when ->(type) { defined?(MoneyColumn) && MoneyColumn::ActiveRecordType === type }
            RBI::Type.simple("::Money")
          when ActiveRecord::Type::Integer
            RBI::Type.simple("::Integer")
          when ->(type) {
                 defined?(ActiveRecord::Encryption) && ActiveRecord::Encryption::EncryptedAttributeType === type
               }
            # Reflect to see if `ActiveModel::Type::Value` is being used first.
            getter_type = RBI::Type.parse_string(Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(column_type))

            # Fallback to String as `ActiveRecord::Encryption::EncryptedAttributeType` inherits from
            # `ActiveRecord::Type::Text` which inherits from `ActiveModel::Type::String`.
            return RBI::Type.simple("::String") if getter_type == RBI::Type.untyped

            as_non_nilable_if_persisted_and_not_nullable(getter_type, column_nullability:)
          when ActiveRecord::Type::String
            RBI::Type.simple("::String")
          when ActiveRecord::Type::Date
            RBI::Type.simple("::Date")
          when ActiveRecord::Type::Decimal
            RBI::Type.simple("::BigDecimal")
          when ActiveRecord::Type::Float
            RBI::Type.simple("::Float")
          when ActiveRecord::Type::Boolean
            RBI::Type.boolean
          when ActiveRecord::Type::DateTime, ActiveRecord::Type::Time
            RBI::Type.simple("::Time")
          when ActiveRecord::AttributeMethods::TimeZoneConversion::TimeZoneConverter
            RBI::Type.simple("::ActiveSupport::TimeWithZone")
          when ActiveRecord::Enum::EnumType
            RBI::Type.simple("::String")
          when ActiveRecord::Type::Binary
            RBI::Type.simple("::String")
          when ActiveRecord::Type::Serialized
            serialized_column_type(column_type)
          when ->(type) {
                 (defined?(ActiveRecord::Normalization::NormalizedValueType) &&
                   ActiveRecord::Normalization::NormalizedValueType === type) ||
                   (defined?(ActiveModel::Attributes::Normalization::NormalizedValueType) &&
                     ActiveModel::Attributes::Normalization::NormalizedValueType === type)
               }
            type_for_activerecord_value(column_type.cast_type, column_nullability:)
          when ->(type) {
                 defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Uuid) &&
                   ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Uuid === type
               }
            RBI::Type.simple("::String")
          when ->(type) {
                 defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Cidr) &&
                   ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Cidr === type
               }
            RBI::Type.simple("::IPAddr")
          when ->(type) {
                 defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Hstore) &&
                   ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Hstore === type
               }
            RBI::Type.generic("T::Hash", RBI::Type.simple("::String"), RBI::Type.simple("::String"))
          when ->(type) {
                 defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Interval) &&
                   ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Interval === type
               }
            RBI::Type.simple("::ActiveSupport::Duration")
          when ->(type) {
                 defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array) &&
                   ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array === type
               }
            RBI::Type.generic("T::Array", type_for_activerecord_value(column_type.subtype, column_nullability:))
          when ->(type) {
                 defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Bit) &&
                   ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Bit === type
               }
            RBI::Type.simple("::String")
          when ->(type) {
                 defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::BitVarying) &&
                   ActiveRecord::ConnectionAdapters::PostgreSQL::OID::BitVarying === type
               }
            RBI::Type.simple("::String")
          when ->(type) {
                 defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Range) &&
                   ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Range === type
               }
            RBI::Type.generic("T::Range", type_for_activerecord_value(column_type.subtype, column_nullability:))
          when ->(type) {
                 defined?(ActiveRecord::Locking::LockingType) &&
                   ActiveRecord::Locking::LockingType === type
               }
            as_non_nilable_if_persisted_and_not_nullable(RBI::Type.simple("::Integer"), column_nullability:)
          when ->(type) {
                 defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Enum) &&
                   ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Enum === type
               }
            RBI::Type.simple("::String")
          else
            as_non_nilable_if_persisted_and_not_nullable(
              RBI::Type.parse_string(ActiveModelTypeHelper.type_for(column_type)),
              column_nullability: column_nullability,
            )
          end
        end

        #: (RBI::Type base_type, column_nullability: bool) -> RBI::Type
        def as_non_nilable_if_persisted_and_not_nullable(base_type, column_nullability:)
          # It's possible that when ActiveModel::Type::Value is used, the signature being reflected on in
          # ActiveModelTypeHelper.type_for(type_value) may say the type can be nilable. However, if the type is
          # persisted and the column is not nullable, we can assume it's not nilable.
          return as_non_nilable_type(base_type) if @column_type_option.persisted? && !column_nullability

          base_type
        end

        #: (ActiveRecord::Enum::EnumType column_type) -> RBI::Type
        def enum_setter_type(column_type)
          # In Rails < 7 this method is private. When support for that is dropped we can call the method directly
          case column_type.send(:subtype)
          when ActiveRecord::Type::Integer
            RBI::Type.any(RBI::Type.simple("::String"), RBI::Type.simple("::Symbol"), RBI::Type.simple("::Integer"))
          else
            RBI::Type.any(RBI::Type.simple("::String"), RBI::Type.simple("::Symbol"))
          end
        end

        #: (ActiveRecord::Type::Serialized column_type) -> RBI::Type
        def serialized_column_type(column_type)
          case column_type.coder
          when ActiveRecord::Coders::YAMLColumn
            case column_type.coder.object_class
            when Array.singleton_class
              RBI::Type.generic("T::Array", RBI::Type.untyped)
            when Hash.singleton_class
              RBI::Type.generic("T::Hash", RBI::Type.untyped, RBI::Type.untyped)
            else
              RBI::Type.untyped
            end
          else
            RBI::Type.untyped
          end
        end

        #: (untyped column_type) -> bool
        def not_nilable_serialized_column?(column_type)
          return false unless column_type.is_a?(ActiveRecord::Type::Serialized)
          return false unless column_type.coder.is_a?(ActiveRecord::Coders::YAMLColumn)

          [Array.singleton_class, Hash.singleton_class].include?(column_type.coder.object_class.singleton_class)
        end
      end
    end
  end
end
