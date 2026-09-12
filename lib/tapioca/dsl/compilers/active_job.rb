# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveJob::Base)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveJob` generates RBI files for subclasses of
      # [`ActiveJob::Base`](https://api.rubyonrails.org/classes/ActiveJob/Base.html).
      #
      # For example, with the following `ActiveJob` subclass:
      #
      # ~~~rb
      # class NotifyUserJob < ActiveJob::Base
      #   sig { params(user: User).returns(Mail) }
      #   def perform(user)
      #     # ...
      #   end
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `notify_user_job.rbi` with the following content:
      #
      # ~~~rbi
      # # notify_user_job.rbi
      # # typed: true
      # class NotifyUserJob
      #   sig do
      #     params(
      #       user: User,
      #       block: T.nilable(T.proc.params(job: NotifyUserJob).void),
      #     ).returns(T.any(NotifyUserJob, FalseClass))
      #   end
      #   def self.perform_later(user, &block); end
      #
      #   sig { params(user: User).returns(Mail) }
      #   def self.perform_now(user); end
      # end
      # ~~~
      #: [ConstantType = singleton(::ActiveJob::Base)]
      class ActiveJob < Compiler
        # @override
        #: -> void
        def decorate
          return unless constant.method_defined?(:perform, false)

          root.create_path(constant) do |job|
            method = constant.instance_method(:perform)
            constant_name = type_name_of(constant) #: as !nil
            parameters = compile_method_parameters_to_rbi(method)
            return_type = compile_method_return_type_to_rbi(method)

            job.create_method(
              "perform_later",
              parameters: perform_later_parameters(parameters, constant_name),
              return_type: "T.any(#{constant_name}, FalseClass)",
              class_method: true,
            )

            job.create_method(
              "perform_now",
              parameters: parameters,
              return_type: return_type,
              class_method: true,
            )
          end
        end

        private

        # Resolves a constant into a valid Sorbet type reference,
        # applying `T.untyped` for any unfixed generic type variables.
        #
        # @example
        #   type_name_of(StandardJob) # => "::StandardJob"
        #   type_name_of(GenericJob)  # => "::SomeModule::GenericJob[T.untyped]"
        #: (Module[top] constant) -> String?
        def type_name_of(constant)
          type_name = qualified_name_of(constant)
          return type_name if !type_name || type_name.end_with?("]")

          type_variables = Runtime::GenericTypeRegistry.lookup_type_variables(constant)
          return type_name unless type_variables

          type_variables = type_variables.reject(&:fixed?)
          return type_name if type_variables.empty?

          "#{type_name}[#{type_variables.map { "T.untyped" }.join(", ")}]"
        end

        #: (Array[RBI::TypedParam] parameters, String constant_name) -> Array[RBI::TypedParam]
        def perform_later_parameters(parameters, constant_name)
          if ::Gem::Requirement.new(">= 7.0").satisfied_by?(::ActiveJob.gem_version)
            parameters.reject! { |typed_param| RBI::BlockParam === typed_param.param }
            parameters + [create_block_param(
              "block",
              type: "T.nilable(T.proc.params(job: #{constant_name}).void)",
            )]
          else
            parameters
          end
        end

        class << self
          # @override
          #: -> Enumerable[Module[top]]
          def gather_constants
            descendants_of(::ActiveJob::Base)
          end
        end
      end
    end
  end
end
