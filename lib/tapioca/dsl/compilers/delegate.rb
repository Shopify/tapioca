# typed: true
# frozen_string_literal: true

return unless Module.respond_to?(:delegate)

require "tapioca/dsl/extensions/delegate"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::Delegate` generates RBI files for classes that use the `delegate` method
      # from ActiveSupport.
      #
      # For a class like:
      #
      # ```ruby
      # class Delegator
      #  sig { returns(Target) }
      #  attr_reader :target
      #
      #  delegate :method, to: :target
      # end
      #
      # class Target
      #  sig { returns(String) }
      #  def method = "hi"
      # end
      # ```
      #
      # This compiler will generate the following RBI file:
      #
      # ```rbi
      # class Delegator
      #  sig { returns(Target) }
      #  attr_reader :target
      #
      #  sig { returns(String) }
      #  def method; end
      # end
      # ```
      #
      # The `delegate` method can also take the `prefix`, `private` and `allow_nil` options but is not intelligent
      # about discovering types from instance variables, class_variables and constants - if you delegate to a target
      # whose type is not discoverable statically, the type will default to T.untyped
      #
      # Delegates that _themselves_ return a `T.untyped` value will not be generated in the RBI file, since Sorbet
      # already generates a `T.untyped` return by default
      #
      class Delegate < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.all(::Module, Extensions::Module) } }

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[::Module]) }
          def gather_constants
            return [] unless defined?(Tapioca::Dsl::Compilers::Extensions::Module)

            all_classes.grep(Tapioca::Dsl::Compilers::Extensions::Module).select do |c|
                T.unsafe(c).__tapioca_delegated_methods.any?
            end
          end
        end

        sig { override.void }
        def decorate
          root.create_path(constant) do |klass|
            constant.__tapioca_delegated_methods.each do |delegated_method|
              delegated_method[:methods].each do |method|
                # We don't handle delegations to instance, class and global variables
                next if delegated_method[:to].start_with?("@", "$")

                constant_target = if delegated_method[:to] == :class
                  constant
                elsif delegated_method[:to].start_with?(/[A-Z]/)
                  target_klass = constantize(delegated_method[:to], namespace: constant)
                  next unless Module === target_klass

                  target_klass
                else
                  false
                end

                sig = if constant_target
                  signature_of(constant_target.singleton_method(method))
                else
                  signature_of(constant.instance_method(delegated_method[:to]))
                end

                next unless sig

                delegate_klass = if delegated_method[:allow_nil]
                  sig.return_type.unwrap_nilable.raw_type
                else
                  sig.return_type.raw_type
                end

                next if delegate_klass == T.untyped

                visibility = if delegated_method[:private]
                  RBI::Private.new
                else
                  RBI::Public.new
                end

                method_def = if constant_target
                  constant_target.singleton_method(method)
                else
                  delegate_klass.instance_method(method)
                end

                method_name = [delegated_method[:prefix], method.name.to_s].compact.join("_")

                method_return_type = if delegated_method[:allow_nil]
                  non_nilable = compile_method_return_type_to_rbi(method_def)
                  "T.nilable(#{non_nilable})"
                else
                  compile_method_return_type_to_rbi(method_def)
                end

                klass.create_method(
                  method_name,
                  parameters: compile_method_parameters_to_rbi(method_def),
                  return_type: method_return_type,
                  class_method: false,
                  visibility: visibility,
                )
              end
            end
          end
        end
      end
    end
  end
end
