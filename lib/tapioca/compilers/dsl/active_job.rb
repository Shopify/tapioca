# typed: strict
# frozen_string_literal: true

require "parlour"

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
      #   sig { params(user: T.untyped).returns(NotifyUserJob) }
      #   def self.perform_later(user); end
      #
      #   sig { params(user: T.untyped).returns(NotifyUserJob) }
      #   def self.perform_now(user); end
      # end
      # ~~~
      class ActiveJob < Base
        extend T::Sig

        sig { override.params(root: Parlour::RbiGenerator::Namespace, constant: T.class_of(::ActiveJob::Base)).void }
        def decorate(root, constant)
          root.path(constant) do |job|
            next unless constant.instance_methods(false).include?(:perform)

            method = constant.instance_method(:perform)
            parameters = compile_method_parameters_to_parlour(method)

            %w[perform_later perform_now].each do |name|
              create_method(
                job,
                name,
                parameters: parameters,
                return_type: constant.name,
                class_method: true
              )
            end
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
