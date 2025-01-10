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

                delegate_sig = if delegated_method[:to] == :class || delegated_method[:to].start_with?(/[A-Z]/)
                  ClassMethodDelegate.new(constant, method, **delegated_method.except(:methods))
                else
                  DelegateMethod.new(constant, method, **delegated_method.except(:methods))
                end

                parameters = compile_method_parameters_to_rbi(delegate_sig.method_def)
                return_type = delegate_sig.maybe_wrap_return(
                  compile_method_return_type_to_rbi(
                    delegate_sig.method_def,
                  ),
                )

                klass.create_method(
                  delegate_sig.method_name,
                  parameters:,
                  return_type:,
                  class_method: false,
                  visibility: delegate_sig.visibility,
                )

              # if the target of the delegate is a constant, but not resolvable, we skip it,
              # or if the target of the delegate is a method, but the return type of that method
              # doesn't hold a signature for this the method we're looking for, we skip it.
              rescue UntypedDelegate
                next
              end
            end
          end
        end

        class UntypedDelegate < StandardError; end

        class DelegateMethod
          include Runtime::Reflection
          extend Runtime::Reflection

          attr_reader :klass, :method, :target, :allow_nil, :prefix, :private

          def initialize(klass, method, to:, allow_nil: false, prefix: nil, private: false)
            @klass = klass
            @method = method
            @target = to
            @allow_nil = allow_nil
            @prefix = prefix
            @private = private
          end

          def target_klass
            @target_klass ||= klass
          end

          def method_def
            @method_def ||= target_return_type.instance_method(method)
          end

          def method_name
            if prefix == true
              [@target, method.name.to_s].compact.join("_")
            else
              [prefix, method.name.to_s].compact.join("_")
            end
          end

          def visibility
            private ? RBI::Private.new : RBI::Public.new
          end

          def target_method
            target_klass.instance_method(target)
          end

          def maybe_wrap_return(type)
            allow_nil ? "T.nilable(#{type})" : type
          end

          private

          def target_method_signature
            signature_of(target_method)
          end

          def target_return_type
            return @target_return_type if defined?(@target_return_type)

            @target_return_type = if allow_nil
              target_method_signature.return_type.unwrap_nilable.raw_type
            else
              target_method_signature.return_type.raw_type
            end

            raise UntypedDelegate if @target_return_type == T.untyped

            @target_return_type
          end
        end

        class ClassMethodDelegate < DelegateMethod
          def target_klass
            return @target_klass if defined?(@target_klass)

            @target_klass = if target == :class
              @klass
            elsif target.start_with?(/[A-Z]/)
              constantize(target)
            end

            raise UntypedDelegate if @target_klass.nil?
            raise UntypedDelegate if @target_klass == UNDEFINED_CONSTANT
            raise UntypedDelegate unless Module === @target_klass

            @target_klass
          end

          def method_def
            @method_def ||= target_klass.singleton_method(method)
          end

          def target_method
            target_klass.singleton_method(method)
          end
        end
      end
    end
  end
end
