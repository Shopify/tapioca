# typed: strict
# frozen_string_literal: true

return unless defined?(Ripper)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::Ripper` provides RBI definitions for the
      # C-defined constants and the dynamically generated event methods of
      # `Ripper`.
      class Ripper < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T::Class[::Ripper] } }

        sig { override.void }
        def decorate
          root.create_path(constant) do |klass|
            root.create_constant(
              "#{constant}::PARSER_EVENT_TABLE",
              value: "T.let(T.unsafe(nil), T::Hash[::Symbol, ::Integer])",
            )

            root.create_constant(
              "#{constant}::SCANNER_EVENT_TABLE",
              value: "T.let(T.unsafe(nil), T::Hash[::Symbol, ::Integer])",
            )

            ::Ripper.constants.grep(/^EXPR_/).each do |expr|
              root.create_constant(
                "#{constant}::#{expr}",
                value: "T.let(T.unsafe(nil), ::Integer)",
              )
            end

            ::Ripper::PARSER_EVENT_TABLE.each do |event, arity|
              klass.create_method(
                "on_#{event}",
                parameters: Array.new(arity) do |index|
                  create_param("param#{index}", type: "T.untyped")
                end,
                return_type: "T.untyped",
              )
            end

            ::Ripper::SCANNER_EVENT_TABLE.each_key do |event|
              klass.create_method(
                "on_#{event}",
                parameters: [create_param("value", type: "::String")],
                return_type: "T.untyped",
              )
            end
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            [::Ripper]
          end
        end
      end
    end
  end
end
