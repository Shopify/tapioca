# typed: strict
# frozen_string_literal: true

return unless defined?(Sidekiq::Worker)

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
      #
      # If your project uses `ActiveSupport` as well, then the compiler will automatically add its classes
      # as accepted values for the `interval` parameter:
      # * `self.perform_at` will also accept a `ActiveSupport::TimeWithZone` value
      # * `self.perform_in` will also accept a `ActiveSupport::Duration` value
      #: [ConstantType = singleton(::Sidekiq::Worker)]
      class SidekiqWorker < Compiler
        extend T::Sig

        # @override
        #: -> void
        def decorate
          return unless constant.instance_methods.include?(:perform)

          root.create_path(constant) do |worker|
            method_def = constant.instance_method(:perform)

            async_params = compile_method_parameters_to_rbi(method_def)

            # `perform_at` and is just an alias for `perform_in` so both methods technically
            # accept a datetime, time, or numeric but we're typing them differently so they
            # semantically make sense.
            at_return_type = if defined?(ActiveSupport::TimeWithZone)
              "T.any(DateTime, Time, ActiveSupport::TimeWithZone)"
            else
              "T.any(DateTime, Time)"
            end
            at_params = [
              create_param("interval", type: at_return_type),
              *async_params,
            ]
            in_return_type = if defined?(ActiveSupport::Duration)
              "T.any(Numeric, ActiveSupport::Duration)"
            else
              "Numeric"
            end
            in_params = [
              create_param("interval", type: in_return_type),
              *async_params,
            ]

            generate_perform_method(worker, "perform_async", async_params)
            generate_perform_method(worker, "perform_at", at_params)
            generate_perform_method(worker, "perform_in", in_params)
          end
        end

        class << self
          extend T::Sig

          # @override
          #: -> T::Enumerable[Module]
          def gather_constants
            all_classes.select { |c| Sidekiq::Worker > c }
          end
        end

        private

        #: (RBI::Scope worker, String method_name, Array[RBI::TypedParam] parameters) -> void
        def generate_perform_method(worker, method_name, parameters)
          if constant.method(method_name.to_sym).owner == Sidekiq::Worker::ClassMethods
            worker.create_method(method_name, parameters: parameters, return_type: "String", class_method: true)
          end
        end
      end
    end
  end
end
