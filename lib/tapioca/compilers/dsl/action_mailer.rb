# typed: strict
# frozen_string_literal: true

require "parlour"

begin
  require "action_mailer"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::Dsl::ActionMailer` generates RBI files for subclasses of `ActionMailer::Base`
      # (see https://api.rubyonrails.org/classes/ActionMailer/Base.html).
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
      # this generator will produce the RBI file `notifier_mailer.rbi` with the following content:
      #
      # ~~~rbi
      # # notifier_mailer.rbi
      # # typed: true
      # class NotifierMailer
      #   sig { params(customer_id: T.untyped).returns(::ActionMailer::MessageDelivery) }
      #   def self.notify_customer(customer_id); end
      # end
      # ~~~
      class ActionMailer < Base
        extend T::Sig

        sig { override.params(root: Parlour::RbiGenerator::Namespace, constant: T.class_of(::ActionMailer::Base)).void }
        def decorate(root, constant)
          root.path(constant) do |k|
            constant.action_methods.to_a.each do |mailer_method|
              method_def = constant.instance_method(mailer_method)
              parameters = compile_method_parameters_to_parlour(method_def)
              create_method(
                k,
                mailer_method,
                parameters: parameters,
                return_type: '::ActionMailer::MessageDelivery',
                class_method: true
              )
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          ::ActionMailer::Base.descendants.reject(&:abstract?)
        end
      end
    end
  end
end
