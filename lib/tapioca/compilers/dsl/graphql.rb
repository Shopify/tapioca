# typed: strict
# frozen_string_literal: true

require "parlour"

begin
  require "graphql"
rescue LoadError
  # means Graphql is not installed,
  # so let's not even define the generator.
  return
end

module Tapioca
  module Compilers
    module Dsl
      class Graphql < Base
        extend T::Sig

        sig do
          override
            .params(
              root: Parlour::RbiGenerator::Namespace,
              constant: T.class_of(::GraphQL::Schema::InputObject)
            )
            .void
        end
        def decorate(root, constant)
          arguments = T.let(
            T.unsafe(constant).arguments,
            T::Hash[String, ::GraphQL::Schema::Argument]
          )
          return if arguments.empty?
          puts constant

          root.path(constant) do |k|
            arguments.values.each do |argument|
              type = type_for(argument)

              k.create_method(argument.instance_variable_get(:@name), return_type: type)
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          classes = T.cast(ObjectSpace.each_object(Class), T::Enumerable[Class])
          classes.select do |c|
            c < ::GraphQL::Schema::InputObject
          end.reject do |c|
            c.name&.include?("GraphQL")
          end
        end

        private

        sig { params(argument: ::GraphQL::Schema::Argument).returns(String) }
        def type_for(argument)
          required = argument.instance_variable_get(:@null) # argument.type.is_a?(::GraphQL::Schema::NonNull)
          type = argument.instance_variable_get(:@type_expr)

          if required
            type
          else
            "T.nilable(#{type})"
          end
        end
      end
    end
  end
end
