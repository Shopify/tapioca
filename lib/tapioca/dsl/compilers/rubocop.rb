# typed: strict
# frozen_string_literal: true

return unless defined?(RuboCop::AST::NodePattern::Macros)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::RuboCop` generates types for RuboCop cops.
      # RuboCop uses macros to define methods leveraging "AST node patterns".
      # For example, in this cop
      #
      #   class MyCop < Base
      #     def_node_matcher :matches_some_pattern?, "..."
      #
      #     def on_send(node)
      #       return unless matches_some_pattern?(node)
      #       # ...
      #     end
      #   end
      #
      # the use of `def_node_matcher` will generate the method
      # `matches_some_pattern?`, for which this compiler will generate a `sig`.
      #
      # More complex uses are also supported, including:
      #
      # - Usage of `def_node_search`
      # - Parameter specification
      # - Default parameter specification, including generating sigs for
      #   `without_defaults_*` methods
      class RuboCop < Compiler
        ConstantType = type_member do
          { fixed: T.all(Module, Extensions::RuboCop) }
        end

        class << self
          extend T::Sig
          sig { override.returns(T::Array[T.all(Module, Extensions::RuboCop)]) }
          def gather_constants
            T.cast(
              extenders_of(::RuboCop::AST::NodePattern::Macros).select { |constant| name_of(constant) },
              T::Array[T.all(Module, Extensions::RuboCop)],
            )
          end
        end

        sig { override.void }
        def decorate
          return if node_methods.empty?

          root.create_path(constant) do |cop_klass|
            node_methods.each do |name|
              create_method_from_def(cop_klass, constant.instance_method(name))
            end
          end
        end

        private

        sig { returns(T::Array[Extensions::RuboCop::MethodName]) }
        def node_methods
          constant.__tapioca_node_methods
        end
      end
    end
  end
end
