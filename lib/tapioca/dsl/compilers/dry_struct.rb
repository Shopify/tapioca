# typed: strict
# frozen_string_literal: true

begin
  require "dry-types"
  require "dry-struct"
  require "dry-mondads"
rescue LoadError
  return
end

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::DryStruct` generate types for dry-struct.
      # This gem defines typed struct classes.
      # For example,
      #
      # ~~~rb
      # # user.rb
      # class User < Dry::Struct
      #   attribute :name,    Types::Strict::String
      #   attribute :age,     Types::Strict::Integer
      #   attribute :address, Types::Strict::String.optional
      # end
      # ~~~
      #
      # this compiler will produce an RBI file `user.rbi` with the following content:
      #
      # ~~~rbi
      # # user.rbi
      # # typed: strong
      # class User
      #   sig { returns(String) }
      #   def name; end
      #   sig { returns(Integer) }
      #   def age; end
      #   sig { returns(T.nilable(String)) }
      #   def name; end
      # end
      # ~~~
      class DryStruct < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: ::T.class_of(::Dry::Struct) } }

        sig { override.void }
        def decorate
          compiler = Helpers::DrySchemaAstHelper.new
          root.create_path(constant) do |klass|
            constant.schema.each do |s|
              attribute_info = compiler.visit(s.to_ast)
              sorbet_type = if s.type.class == ::Dry::Types::Maybe
                "::T.any(::Dry::Monads::Maybe::Some, ::Dry::Monads::Maybe::None)"
              else
                self.class.to_sorbet_type(attribute_info[:type], attribute_info[:required])
              end
              klass.create_method(
                attribute_info[:name],
                return_type: sorbet_type,
              )
            end
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(::T::Enumerable[Module]) }
          def gather_constants
            all_classes.select { |c| c < ::Dry::Struct }
          end

          sig { params(type: ::T.untyped, required: ::T::Boolean).returns(::String) }
          def to_sorbet_type(type, required)
            base = if type.is_a?(Helpers::DrySchemaAstHelper::Sum)
              sum_to_sorbet_type(type)
            elsif type.is_a?(Helpers::DrySchemaAstHelper::Schema)
              experimental_schema_to_sorbet_type(type)
            elsif type.is_a?(Helpers::DrySchemaAstHelper::Undefined)
              "::T.untyped"
            elsif type.is_a?(::Array)
              "::T::Array[#{to_sorbet_type(type[0], true)}]"
            elsif type == ::Hash
              "::T::Hash[::T.untyped, ::T.untyped]"
            elsif type == ::Time
              ENV["DRY_PREFER_PLAIN_TIME"] ? "::Time" : "::ActiveSupport::TimeWithZone"
            elsif type == ::Range
              "::T::Range[::T.untyped]"
            elsif type == ::Set
              "::T::Set[::T.untyped]"
            elsif type == ::TrueClass || type == ::FalseClass
              "::T::Boolean"
            elsif type.nil?
              "::NilClass"
            else
              "::#{type.name}"
            end

            if base == "::T.untyped" || base == "::NilClass"
              base
            elsif required
              base
            elsif base.start_with?("::T.nilable")
              base
            elsif base.match?(/\A\{.*\}\z/)
              "::T.nilable(#{base.gsub(/(\A\{ | \}\z)/, "")})"
            else
              "::T.nilable(#{base})"
            end
          end

          sig { params(sum: Helpers::DrySchemaAstHelper::Sum).returns(::String) }
          def sum_to_sorbet_type(sum)
            return "::T.untyped" if sum.include_undefined?

            if sum.include_nilclass?
              sum.delete_nilclass!
              if sum.size < 2
                "::T.nilable(#{to_sorbet_type(sum.types[0], true)})"
              elsif (sum.types - [::TrueClass, ::FalseClass]).empty?
                "::T.nilable(::T::Boolean)"
              else
                "::T.nilable(::T.any(#{sum.types.map { |t| to_sorbet_type(t, true) }.join(", ")}))"
              end
            elsif (sum.types - [::TrueClass, ::FalseClass]).empty?
              "::T::Boolean"
            else
              "::T.any(#{sum.types.map { |t| to_sorbet_type(t, true) }.join(", ")})"
            end
          end

          sig { params(schema: ::T.untyped).returns(::String) }
          def experimental_schema_to_sorbet_type(schema)
            return "::T::Hash[::T.untyped, ::T.untyped]" if schema.empty?

            sigs = schema.map do |i|
              sorbet_type = to_sorbet_type(i[:type], i[:required])
              i[:name].is_a?(::String) ? "'#{i[:name]}' => #{sorbet_type}" : "#{i[:name]}: #{sorbet_type}"
            end

            "{ #{sigs.join(", ")} }"
          end
        end
      end
    end
  end
end
