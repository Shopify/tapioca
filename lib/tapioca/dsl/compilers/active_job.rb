# typed: strict
# frozen_string_literal: true

begin
  require "active_job"
rescue LoadError
  return
end

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
      #   sig { params(user: User).returns(T.any(NotifyUserJob, FalseClass)) }
      #   def self.perform_later(user); end
      #
      #   sig { params(user: User).returns(Mail) }
      #   def self.perform_now(user); end
      # end
      # ~~~
      class ActiveJob < Compiler
        extend T::Sig

        ConstantType = type_member(fixed: T.class_of(::ActiveJob::Base))

        sig { override.void }
        def decorate
          return unless constant.instance_methods(false).include?(:perform)

          root.create_path(constant) do |job|
            method = constant.instance_method(:perform)
            parameters = compile_method_parameters_to_rbi(method)
            return_type = compile_method_return_type_to_rbi(method)

            job.create_method(
              "perform_later",
              parameters: parameters,
              return_type: "T.any(#{name_of(constant)}, FalseClass)",
              class_method: true
            )

            job.create_method(
              "perform_now",
              parameters: parameters,
              return_type: return_type,
              class_method: true
            )
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def self.gather_constants
          descendants_of(::ActiveJob::Base)
        end
      end
    end
  end
end
