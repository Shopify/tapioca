# typed: strict
# frozen_string_literal: true

begin
  require "active_model"
rescue LoadError
  return
end

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveModelAttributes` decorates RBI files for all
      # classes that use [`ActiveModel::Attributes`](https://edgeapi.rubyonrails.org/classes/ActiveModel/Attributes/ClassMethods.html).
      #
      # For example, with the following class:
      #
      # ~~~rb
      # class Shop
      #   include ActiveModel::Attributes
      #
      #   attribute :name, :string
      # end
      # ~~~
      #
      # this compiler will produce an RBI file with the following content:
      # ~~~rbi
      # # typed: true
      #
      # class Shop
      #
      #   sig { returns(T.nilable(::String)) }
      #   def name; end
      #
      #   sig { params(name: T.nilable(::String)).returns(T.nilable(::String)) }
      #   def name=(name); end
      # end
      # ~~~
      class ActiveModelAttributes < Compiler
        extend T::Sig

        sig { override.params(root: RBI::Tree, constant: T.all(Class, ::ActiveModel::Attributes::ClassMethods)).void }
        def decorate(root, constant)
          attribute_methods = attribute_methods_for(constant)
          return if attribute_methods.empty?

          root.create_path(constant) do |klass|
            attribute_methods.each do |method, attribute_type|
              generate_method(klass, method, attribute_type)
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          all_classes.grep(::ActiveModel::Attributes::ClassMethods)
        end

        private

        HANDLED_METHOD_TARGETS = T.let(["attribute", "attribute="], T::Array[String])

        sig { params(constant: ::ActiveModel::Attributes::ClassMethods).returns(T::Array[[::String, ::String]]) }
        def attribute_methods_for(constant)
          constant.attribute_method_matchers.flat_map do |matcher|
            constant.attribute_types.map do |name, value|
              next unless handle_method_matcher?(matcher)

              [matcher.method_name(name), type_for(value)]
            end.compact
          end
        end

        sig do
          params(matcher: ::ActiveModel::AttributeMethods::ClassMethods::AttributeMethodMatcher)
            .returns(T::Boolean)
        end
        def handle_method_matcher?(matcher)
          target = if matcher.respond_to?(:method_missing_target)
            # Pre-Rails 6.0, the field is named "method_missing_target"
            T.unsafe(matcher).method_missing_target
          else
            # Rails 6.0+ has renamed the field to "target"
            matcher.target
          end

          HANDLED_METHOD_TARGETS.include?(target.to_s)
        end

        sig { params(attribute_type_value: ::ActiveModel::Type::Value).returns(::String) }
        def type_for(attribute_type_value)
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
            # we don't want untyped to be wrapped by T.nilable, so just return early
            return "T.untyped"
          end

          as_nilable_type(type)
        end

        sig { params(klass: RBI::Scope, method: String, type: String).void }
        def generate_method(klass, method, type)
          if method.end_with?("=")
            parameter = create_param("value", type: type)
            klass.create_method(
              method,
              parameters: [parameter],
              return_type: type
            )
          else
            klass.create_method(method, return_type: type)
          end
        end
      end
    end
  end
end
