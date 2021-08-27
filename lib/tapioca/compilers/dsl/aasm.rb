# typed: strict
# frozen_string_literal: true

begin
  require "active_record"
  require "aasm"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::Dsl::AASM` generate types for AASM state machines.
      # This gem dynamically defines constants and methods at runtime. For
      # example, given a class:
      #
      #   class MyClass
      #     include AASM
      #
      #     aasm do
      #       state :sleeping, initial: true
      #       state :running, :cleaning
      #
      #       event :run do
      #         transitions from: :sleeping, to: :running
      #       end
      #     end
      #   end
      #
      # This will result in the following constants being defined:
      #
      #   STATE_SLEEPING, STATE_RUNNING, STATE_CLEANING
      #
      # and the following methods being defined:
      #
      #   sleeping?, running?, cleaning?
      #   run, run!, run_without_validation!, may_run?
      #
      class AASM < Tapioca::Compilers::Dsl::Base
        extend T::Sig

        # Taken directly from the AASM::Core::Event class, here:
        # https://github.com/aasm/aasm/blob/0e03746/lib/aasm/core/event.rb#L21-L29
        EVENT_CALLBACKS =
          T.let(
            ["after", "after_commit", "after_transaction", "before", "before_transaction", "ensure", "error",
             "before_success", "success"].freeze,
            T::Array[String]
          )

        sig { override.params(root: RBI::Tree, constant: Module).void }
        def decorate(root, constant)
          # Make sure the thing that's being passed in here actually included
          # AASM
          return unless constant.respond_to?(:aasm)

          # Using T.unsafe here because at this point we know that the object
          # includes AASM
          aasm = T.unsafe(constant).aasm
          return unless aasm

          root.create_path(constant) do |model|
            # Create all of the constants and methods for each state
            aasm.states.each do |state|
              model.create_constant("STATE_#{state.name.upcase}", value: "T.let(T.unsafe(nil), Symbol)")
              model.create_method("#{state.name}?", return_type: "T::Boolean")
            end

            # Create all of the methods for each event
            parameters = [create_rest_param("opts", type: "T.untyped")]
            aasm.events.each do |event|
              model.create_method(event.name.to_s, parameters: parameters)
              model.create_method("#{event.name}!", parameters: parameters)
              model.create_method("#{event.name}_without_validation!", parameters: parameters)
              model.create_method("may_#{event.name}?", return_type: "T::Boolean")
            end

            # Create the overall state machine method, which will return an
            # instance of the PrivateAASMMachine class.
            model.create_method(
              "aasm",
              parameters: [
                create_rest_param("args", type: "T.untyped"),
                create_block_param("block", type: "T.nilable(T.proc.bind(PrivateAASMMachine).void)"),
              ],
              return_type: "PrivateAASMMachine",
              class_method: true
            )

            # Create a private machine class that we can pass around for the
            # purpose of binding various procs passed to methods without having
            # to explicitly bind self in each one.
            model.create_class("PrivateAASMMachine", superclass_name: "AASM::Base") do |machine|
              machine.create_method(
                "event",
                parameters: [
                  create_param("name", type: "T.untyped"),
                  create_opt_param("options", default: "nil", type: "T.untyped"),
                  create_block_param("block", type: "T.proc.bind(PrivateAASMEvent).void"),
                ]
              )

              # Create a private event class that we can pass around for the
              # purpose of binding all of the callbacks without having to
              # explicitly bind self in each one.
              machine.create_class("PrivateAASMEvent", superclass_name: "AASM::Core::Event") do |event|
                EVENT_CALLBACKS.each do |method|
                  event.create_method(
                    method,
                    parameters: [
                      create_block_param("block", type: "T.proc.bind(#{constant.name}).void"),
                    ]
                  )
                end
              end
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          T.cast(ObjectSpace.each_object(::AASM::ClassMethods), T::Enumerable[Module])
        end
      end
    end
  end
end
