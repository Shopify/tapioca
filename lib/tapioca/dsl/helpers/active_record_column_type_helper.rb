# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Helpers
      class ActiveRecordColumnTypeHelper
        extend T::Sig
        include RBIHelper

        sig { params(constant: T.class_of(ActiveRecord::Base)).void }
        def initialize(constant)
          @constant = constant
        end

        sig { params(column_name: String).returns([String, String]) }
        def type_for(column_name)
          return ["T.untyped", "T.untyped"] if do_not_generate_strong_types?(@constant)

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

          if column&.null
            getter_type = as_nilable_type(getter_type) unless not_nilable_serialized_column?(column_type)
            return [getter_type, as_nilable_type(setter_type)]
          end

          if column_name == @constant.primary_key ||
              column_name == "created_at" ||
              column_name == "updated_at"
            getter_type = as_nilable_type(getter_type)
          end

          [getter_type, setter_type]
        end

        private

        sig { params(column_type: T.untyped).returns(String) }
        def type_for_activerecord_value(column_type)
          case column_type
          when defined?(MoneyColumn) && MoneyColumn::ActiveRecordType
            "::Money"
          when ActiveRecord::Type::Integer
            "::Integer"
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
          when defined?(ActiveRecord::ConnectionAdapters::PostgreSQL) &&
            ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Hstore
            "T::Hash[::String, ::String]"
          when defined?(ActiveRecord::ConnectionAdapters::PostgreSQL) &&
            ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array
            "T::Array[#{type_for_activerecord_value(column_type.subtype)}]"
          else
            handle_unknown_type(column_type)
          end
        end

        sig { params(constant: Module).returns(T::Boolean) }
        def do_not_generate_strong_types?(constant)
          Object.const_defined?(:StrongTypeGeneration) &&
            !(constant.singleton_class < Object.const_get(:StrongTypeGeneration))
        end

        sig { params(column_type: BasicObject).returns(String) }
        def handle_unknown_type(column_type)
          return "T.untyped" unless ActiveModel::Type::Value === column_type
          return "T.untyped" if Runtime::GenericTypeRegistry.generic_type_instance?(column_type)

          lookup_return_type_of_method(column_type, :deserialize) ||
            lookup_return_type_of_method(column_type, :cast) ||
            lookup_arg_type_of_method(column_type, :serialize) ||
            "T.untyped"
        end

        sig { params(column_type: ActiveModel::Type::Value, method: Symbol).returns(T.nilable(String)) }
        def lookup_return_type_of_method(column_type, method)
          signature = Runtime::Reflection.signature_of(column_type.method(method))
          return unless signature

          return_type = signature.return_type
          return if return_type == T::Private::Types::Void || return_type == T::Private::Types::NotTyped

          return_type.to_s
        end

        sig { params(column_type: ActiveModel::Type::Value, method: Symbol).returns(T.nilable(String)) }
        def lookup_arg_type_of_method(column_type, method)
          signature = Runtime::Reflection.signature_of(column_type.method(method))
          return unless signature

          # Arg types is an array [name, type] entries, so we desctructure the type of
          # first argument to get the first argument type
          _, first_argument_type = signature.arg_types.first

          first_argument_type.to_s
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
