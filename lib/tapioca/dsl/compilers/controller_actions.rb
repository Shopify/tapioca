# typed: strict
# frozen_string_literal: true

begin
  require "action_controller"
rescue LoadError
  return
end

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::SidekiqWorker` generates RBI files classes that include
      # [`Sidekiq::Worker`](https://github.com/mperham/sidekiq/wiki/Getting-Started).
      #
      # For example, with the following class that includes `Sidekiq::Worker`:
      #
      # ~~~rb
      # class NotifierWorker
      #   include Sidekiq::Worker
      #   def perform(customer_id)
      #     # ...
      #   end
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `notifier_worker.rbi` with the following content:
      #
      # ~~~rbi
      # # notifier_worker.rbi
      # # typed: true
      # class NotifierWorker
      #   sig { params(customer_id: T.untyped).returns(String) }
      #   def self.perform_async(customer_id); end
      #
      #   sig { params(interval: T.any(DateTime, Time), customer_id: T.untyped).returns(String) }
      #   def self.perform_at(interval, customer_id); end
      #
      #   sig { params(interval: Numeric, customer_id: T.untyped).returns(String) }
      #   def self.perform_in(interval, customer_id); end
      # end
      # ~~~
      class ControllerActions < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::ActionController::Base) } }

        sig { override.void }
        def decorate
          public_methods = constant.instance_methods(false)
          return if public_methods.empty?

          root.create_path(constant) do |klass|
            public_methods.each do |method_name|
              method = constant.instance_method(method_name)
              signature = signature_of(method)
              next if signature

              klass.create_method(method_name.to_s, return_type: "void")
            end
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes.select { |c| c < ActionController::Base }
          end
        end
      end
    end
  end
end
