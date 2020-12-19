# typed: strict
# frozen_string_literal: true

require "parlour"

begin
  require "sidekiq"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::Dsl::SidekiqWorker` generates RBI files classes that include
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
      # this generator will produce the RBI file `notifier_worker.rbi` with the following content:
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
      class SidekiqWorker < Base
        extend T::Sig

        sig { override.params(root: Parlour::RbiGenerator::Namespace, constant: T.class_of(::Sidekiq::Worker)).void }
        def decorate(root, constant)
          return [] unless constant.instance_methods.include?(:perform)

          root.path(constant) do |worker|
            method_def = constant.instance_method(:perform)

            perform_async_params = compile_method_parameters_to_parlour(method_def)

            # `perform_at` and is just an alias for `perform_in` so both methods technically
            # accept a datetime, time, or numeric but we're typing them differently so they
            # semantically make sense.
            perform_at_params = [
              Parlour::RbiGenerator::Parameter.new('interval', type: 'T.any(DateTime, Time)'),
              *perform_async_params,
            ]
            perform_in_params = [
              Parlour::RbiGenerator::Parameter.new('interval', type: 'Numeric'),
              *perform_async_params,
            ]

            create_method(worker, 'perform_async', parameters: perform_async_params, return_type: 'String', class_method: true)
            create_method(worker, 'perform_at', parameters: perform_at_params, return_type: 'String', class_method: true)
            create_method(worker, 'perform_in', parameters: perform_in_params, return_type: 'String', class_method: true)
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          classes = T.cast(ObjectSpace.each_object(Class), T::Enumerable[Class])
          classes.select { |c| c < Sidekiq::Worker }
        end
      end
    end
  end
end
