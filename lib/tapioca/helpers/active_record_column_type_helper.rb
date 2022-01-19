# typed: strict
# frozen_string_literal: true

class ActiveRecordColumnTypeHelper
  extend T::Sig

  sig { params(constant: T.class_of(ActiveRecord::Base)).void }
  def initialize(constant)
    @constant = constant
  end

  sig { params(column_name: String).returns([String, String]) }
  def type_for(column_name)
    return ["T.untyped", "T.untyped"] if do_not_generate_strong_types?(@constant)

    column_type = @constant.attribute_types[column_name]

    getter_type =
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
        "::DateTime"
      when ActiveRecord::AttributeMethods::TimeZoneConversion::TimeZoneConverter
        "::ActiveSupport::TimeWithZone"
      else
        handle_unknown_type(column_type)
      end

    column = @constant.columns_hash[column_name]
    setter_type = getter_type

    if column&.null
      return ["T.nilable(#{getter_type})", "T.nilable(#{setter_type})"]
    end

    if column_name == @constant.primary_key ||
        column_name == "created_at" ||
        column_name == "updated_at"
      getter_type = "T.nilable(#{getter_type})"
    end

    [getter_type, setter_type]
  end

  private

  sig { params(constant: Module).returns(T::Boolean) }
  def do_not_generate_strong_types?(constant)
    Object.const_defined?(:StrongTypeGeneration) &&
        !(constant.singleton_class < Object.const_get(:StrongTypeGeneration))
  end

  sig { params(column_type: Object).returns(String) }
  def handle_unknown_type(column_type)
    return "T.untyped" unless ActiveModel::Type::Value === column_type
    return "T.untyped" if Tapioca::GenericTypeRegistry.generic_type_instance?(column_type)

    lookup_return_type_of_method(column_type, :deserialize) ||
      lookup_return_type_of_method(column_type, :cast) ||
      lookup_arg_type_of_method(column_type, :serialize) ||
      "T.untyped"
  end

  sig { params(column_type: ActiveModel::Type::Value, method: Symbol).returns(T.nilable(String)) }
  def lookup_return_type_of_method(column_type, method)
    signature = T::Private::Methods.signature_for_method(column_type.method(method))
    return unless signature

    return_type = signature.return_type
    return if return_type == T::Private::Types::Void || return_type == T::Private::Types::NotTyped

    return_type.to_s
  end

  sig { params(column_type: ActiveModel::Type::Value, method: Symbol).returns(T.nilable(String)) }
  def lookup_arg_type_of_method(column_type, method)
    signature = T::Private::Methods.signature_for_method(column_type.method(method))
    return unless signature

    # Arg types is an array [name, type] entries, so we desctructure the type of
    # first argument to get the first argument type
    _, first_argument_type = signature.arg_types.first

    first_argument_type.to_s
  end
end
