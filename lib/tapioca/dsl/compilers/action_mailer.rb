# typed: strict
# frozen_string_literal: true

begin
  require "action_mailer"
rescue LoadError
  return
end

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActionMailer` generates RBI files for subclasses of
      # [`ActionMailer::Base`](https://api.rubyonrails.org/classes/ActionMailer/Base.html).
      #
      # For example, with the following `ActionMailer` subclass:
      #
      # ~~~rb
      # class NotifierMailer < ActionMailer::Base
      #   def notify_customer(customer_id)
      #     # ...
      #   end
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `notifier_mailer.rbi` with the following content:
      #
      # ~~~rbi
      # # notifier_mailer.rbi
      # # typed: true
      # class NotifierMailer
      #   sig { params(customer_id: T.untyped).returns(::ActionMailer::MessageDelivery) }
      #   def self.notify_customer(customer_id); end
      # end
      # ~~~
      class ActionMailer < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::ActionMailer::Base) } }

        sig { override.void }
        def decorate
          root.create_path(constant) do |mailer|
            constant.action_methods.to_a.each do |mailer_method|
              method_def = constant.instance_method(mailer_method)
              parameters = compile_method_parameters_to_rbi(method_def)
              mailer.create_method(
                mailer_method,
                parameters: parameters,
                return_type: "::ActionMailer::MessageDelivery",
                class_method: true
              )
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def self.gather_constants
          descendants_of(::ActionMailer::Base).reject(&:abstract?)
        end
      end
    end
  end
end
