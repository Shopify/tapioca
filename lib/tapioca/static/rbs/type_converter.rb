# typed: true
# frozen_string_literal: true

module Tapioca
  module Static
    module Rbs
      class TypeConverter
        extend T::Sig
        include Tapioca::RBIHelper

        sig { params(converter: Converter, type_params: T::Array[RBS::AST::TypeParam]).void }
        def initialize(converter, type_params = [])
          @converter = converter
          @type_params = type_params
          @type_param_names = T.let(type_params.map(&:to_s), T::Array[String])
        end

        sig { returns(T::Array[RBS::AST::TypeParam]) }
        attr_reader :type_params

        sig { params(type: T.untyped).returns(T::Types::Base) }
        def convert(type)
          case type
          when RBS::Types::Alias
            string_holder(type.name.to_s)
          when RBS::Types::Bases::Any
            T.untyped
          when RBS::Types::Bases::Bool
            T::Boolean
          when RBS::Types::Bases::Bottom
            T.untyped
          when RBS::Types::Bases::Instance
            T::Types::AttachedClassType::Private.const_get(:INSTANCE)
          when RBS::Types::Bases::Nil
            T::Utils.coerce(NilClass)
          when RBS::Types::Bases::Self
            T.self_type
          when RBS::Types::Bases::Top
            T::Utils.coerce(BasicObject)
          when RBS::Types::Bases::Void
            T::Private::Types::Void.new
          when ::RBS::Types::Bases::Class
            # unhandled
          when RBS::Types::ClassInstance
            name = type.name
            if !type.args.empty? &&
                name.namespace.empty? &&
                name.class? &&
                ["Hash", "Array", "Set", "Enumerable", "Enumerable::Lazy", "Enumerator",
                 "Range",].include?(name.relative!.to_s)
              name = name.relative!.with_prefix(Namespace("::T"))
            end
            name = name.to_s

            type_variables = type.args.map { |arg| convert(arg).to_s }.join(", ")
            name += "[#{type_variables}]" unless type_variables.empty?

            string_holder(name)
          when RBS::Types::Interface
            name = case type.name.name.to_s
            when "_Each"
              "T::Enumerable"
            else
              type.name.to_s
            end
            type_variables = type.args.map { |arg| convert(arg).to_s }.join(", ")
            name += "[#{type_variables}]" unless type_variables.empty?

            string_holder(name)
          when RBS::Types::Intersection
            T.unsafe(T).all(*convert_all(type.types))
          when RBS::Types::Literal
            T.untyped
          when RBS::Types::Optional
            type = convert(type.type)
            if T::Types::Untyped === type
              type
            else
              T.nilable(T.unsafe(type))
            end
          when RBS::Types::Proc
            converter = ParameterConverter.new(self, type.type, type.block)
            params = converter.convert.to_h { |p| [p.name, p.type] }
            T::Types::Proc.new(params, convert(type.type.return_type))
          when RBS::Types::Record
            T::Utils.coerce(type.fields.to_h { |key, type| [key, convert(type)] })
          when RBS::Types::Tuple
            T::Utils.coerce(convert_all(type.types))
          when RBS::Types::Union
            union_type = T.unsafe(T).any(*convert_all(type.types))

            if union_type.to_s == "T.nilable(T.untyped)"
              T.untyped
            else
              union_type
            end
          when RBS::Types::Variable
            if @type_param_names.include?(type.name.to_s)
              T::Types::TypeParameter.new(type.name.to_sym)
            else
              string_holder(type.name.to_s)
            end
          when RBS::Types::ClassSingleton
            # Don't know how to handle this...
            T.untyped
          when RBS::Types::Block
            converter = ParameterConverter.new(self, type.type, nil)
            params = converter.convert.to_h { |p| [p.name, p.type] }
            block = T::Types::Proc.new(params, convert(type.type.return_type))
            block = T.nilable(T.unsafe(block)) unless type.required
            block
          else
            raise "Unknown RBS type: #{type.class}>"
          end
        end

        def convert_all(types)
          types.map { |type| convert(type) }
        end

        def to_string(type)
          type = convert(type) unless T::Types::Base === type
          sanitize_signature_types(type.to_s)
        end

        sig { params(visibility: Symbol).returns(RBI::Visibility) }
        def visibility(visibility)
          case visibility
          when :public
            RBI::Public.new
          when :private
            RBI::Private.new
          else
            raise "Unknown visibility: `#{visibility}`"
          end
        end

        private

        sig { params(type_name: String).returns(T::Private::Types::StringHolder) }
        def string_holder(type_name)
          T.unsafe(T::Private::Types::StringHolder).new(type_name)
        end
      end
    end
  end
end
