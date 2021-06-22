# typed: strict
# frozen_string_literal: true

begin
  require "active_job"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::Dsl::ActiveJob` generates RBI files for subclasses of
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
      # this generator will produce the RBI file `notify_user_job.rbi` with the following content:
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
      class ActiveJob < Base
        extend T::Sig

        sig { override.params(root: RBI::Tree, constant: T.class_of(::ActiveJob::Base)).void }
        def decorate(root, constant)
          return unless constant.instance_methods(false).include?(:perform)

          root.create_path(constant) do |job|
            method = constant.instance_method(:perform)
            parameters = compile_method_parameters_to_rbi(method)
            return_type = compile_method_return_type_to_rbi(method)

            job.create_method(
              "perform_later",
              parameters: parameters,
              return_type: "T.any(#{constant.name}, FalseClass)",
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
        def gather_constants
          ::ActiveJob::Base.descendants
        end
      end
    end
  end
end
