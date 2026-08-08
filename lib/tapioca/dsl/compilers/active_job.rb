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
            constant_name = T.must(name_of(constant))
            job_type = generic_job_type(constant_name)
            parameters = compile_method_parameters_to_rbi(method)
            return_type = compile_method_return_type_to_rbi(method)

            job.create_method(
              "perform_later",
              parameters: perform_later_parameters(parameters, job_type),
              return_type: "T.any(#{job_type}, FalseClass)",
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

        #: (String constant_name) -> String
        def generic_job_type(constant_name)
          return constant_name unless T::Generic === constant

          type_variables = Runtime::GenericTypeRegistry.lookup_type_variables(constant)
          return constant_name unless type_variables

          type_arguments = type_variables.reject(&:fixed?).map { "T.untyped" }
          return constant_name if type_arguments.empty?

          "#{constant_name}[#{type_arguments.join(", ")}]"
        end

        #: (Array[RBI::TypedParam] parameters, String job_type) -> Array[RBI::TypedParam]
        def perform_later_parameters(parameters, job_type)
          if ::Gem::Requirement.new(">= 7.0").satisfied_by?(::ActiveJob.gem_version)
            parameters.reject! { |typed_param| RBI::BlockParam === typed_param.param }
            parameters + [create_block_param(
              "block",
              type: "T.nilable(T.proc.params(job: #{job_type}).void)",
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
