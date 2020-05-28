# typed: true
# frozen_string_literal: true

require "parlour"
require_relative "../../../../core_ext/class"

begin
  require "state_machines"
rescue LoadError
  # means StateMachines is not installed,
  # so let's not even define the generator.
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `RbiGenerator::StateMachines` generates RBI files for classes that setup a `state_machine`
      # (see https://github.com/state-machines/state_machines). The generator also processes the extra
      # methods generated by [StateMachines Active Record](https://github.com/state-machines/state_machines-activerecord)
      # and [StateMachines ActiveModel](https://github.com/state-machines/state_machines-activemodel) integrations.
      #
      # For example, with the following `Vehicle` class:
      #
      # ~~~rb
      # class Vehicle
      #   state_machine :alarm_state, initial: :active, namespace: :'alarm' do
      #     event :enable do
      #       transition all => :active
      #     end
      #
      #     event :disable do
      #       transition all => :off
      #     end
      #
      #     state :active, :value => 1
      #     state :off, :value => 0
      #   end
      # end
      # ~~~
      #
      # this generator will produce the RBI file `vehicle.rbi` with the following content:
      #
      # ~~~rbi
      # # vehicle.rbi
      # # typed: true
      # class Vehicle
      #   include Vehicle::StateMachineInstanceHelperModule
      #   extend Vehicle::StateMachineClassHelperModule
      # end
      #
      # module Vehicle::StateMachineClassHelperModule
      #   sig { params(event: T.any(String, Symbol)).returns(String) }
      #   def human_alarm_state_event_name(event); end
      #
      #   sig { params(state: T.any(String, Symbol)).returns(String) }
      #   def human_alarm_state_name(state); end
      # end
      #
      # module Vehicle::StateMachineInstanceHelperModule
      #   sig { returns(T::Boolean) }
      #   def alarm_active?; end
      #
      #   sig { returns(T::Boolean) }
      #   def alarm_off?; end
      #
      #   sig { returns(Integer) }
      #   def alarm_state; end
      #
      #   sig { params(value: Integer).returns(Integer) }
      #   def alarm_state=(value); end
      #
      #   sig { params(state: T.any(String, Symbol)).returns(T::Boolean) }
      #   def alarm_state?(state); end
      #
      #   sig { params(args: T.untyped).returns(T::Array[T.any(String, Symbol)]) }
      #   def alarm_state_events(*args); end
      #
      #   sig { returns(T.any(String, Symbol)) }
      #   def alarm_state_name; end
      #
      #   sig { params(args: T.untyped).returns(T::Array[::StateMachines::Transition]) }
      #   def alarm_state_paths(*args); end
      #
      #   sig { params(args: T.untyped).returns(T::Array[::StateMachines::Transition]) }
      #   def alarm_state_transitions(*args); end
      #
      #   sig { returns(T::Boolean) }
      #   def can_disable_alarm?; end
      #
      #   sig { returns(T::Boolean) }
      #   def can_enable_alarm?; end
      #
      #   sig { params(args: T.untyped).returns(T::Boolean) }
      #   def disable_alarm(*args); end
      #
      #   sig { params(args: T.untyped).returns(T::Boolean) }
      #   def disable_alarm!(*args); end
      #
      #   sig { params(args: T.untyped).returns(T.nilable(::StateMachines::Transition)) }
      #   def disable_alarm_transition(*args); end
      #
      #   sig { params(args: T.untyped).returns(T::Boolean) }
      #   def enable_alarm(*args); end
      #
      #   sig { params(args: T.untyped).returns(T::Boolean) }
      #   def enable_alarm!(*args); end
      #
      #   sig { params(args: T.untyped).returns(T.nilable(::StateMachines::Transition)) }
      #   def enable_alarm_transition(*args); end
      #
      #   sig { params(event: T.any(String, Symbol), args: T.untyped).returns(T::Boolean) }
      #   def fire_alarm_state_event(event, *args); end
      #
      #   sig { returns(String) }
      #   def human_alarm_state_name; end
      # end
      # ~~~
      class StateMachines < Base
        extend T::Sig

        sig { override.params(root: Parlour::RbiGenerator::Namespace, constant: ::StateMachines::ClassMethods).void }
        def decorate(root, constant)
          return if constant.state_machines.empty?

          instance_module_name = "#{constant}::StateMachineInstanceHelperModule"
          class_module_name = "#{constant}::StateMachineClassHelperModule"

          instance_module = root.create_module(instance_module_name)
          class_module = root.create_module(class_module_name)

          constant.state_machines.each_value do |machine|
            state_type = state_type_for(machine)

            define_state_accessor(instance_module, machine, state_type)
            define_state_predicate(instance_module, machine)
            define_event_helpers(instance_module, machine)
            define_path_helpers(instance_module, machine)
            define_name_helpers(instance_module, class_module, machine)
            define_scopes(class_module, machine)

            define_state_methods(instance_module, machine)
            define_event_methods(instance_module, machine)
          end

          matching_integration_name = ::StateMachines::Integrations.match(constant)&.integration_name

          case matching_integration_name
          when :active_record
            define_activerecord_methods(instance_module)
          end

          root.path(constant) do |klass|
            klass.create_include(instance_module_name)
            klass.create_extend(class_module_name)
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          Object.descendants.select { |mod| mod < ::StateMachines::InstanceMethods }
        end

        private

        def state_type_for(machine)
          value_types = machine.states.map { |state| state.value.class.name }.uniq

          if value_types.size == 1
            value_types.first
          else
            "T.any(#{value_types.join(', ')})"
          end
        end

        def define_activerecord_methods(instance_module)
          create_method(
            instance_module,
            "changed_for_autosave?",
            return_type: "T::Boolean"
          )
        end

        def define_state_methods(instance_module, machine)
          machine.states.each do |state|
            create_method(
              instance_module,
              "#{state.qualified_name}?",
              return_type: "T::Boolean"
            )
          end
        end

        def define_event_methods(instance_module, machine)
          machine.events.each do |event|
            create_method(
              instance_module,
              "can_#{event.qualified_name}?",
              return_type: "T::Boolean"
            )
            create_method(
              instance_module,
              "#{event.qualified_name}_transition",
              parameters: [Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped")],
              return_type: "T.nilable(::StateMachines::Transition)"
            )
            create_method(
              instance_module,
              event.qualified_name.to_s,
              parameters: [Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped")],
              return_type: "T::Boolean"
            )
            create_method(
              instance_module,
              "#{event.qualified_name}!",
              parameters: [Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped")],
              return_type: "T::Boolean"
            )
          end
        end

        def define_state_accessor(instance_module, machine, state_type)
          attribute = machine.attribute.to_s
          create_method(
            instance_module,
            attribute,
            return_type: state_type
          )
          create_method(
            instance_module,
            "#{attribute}=",
            parameters: [Parlour::RbiGenerator::Parameter.new("value", type: state_type)],
            return_type: state_type
          )
        end

        def define_state_predicate(instance_module, machine)
          create_method(
            instance_module,
            "#{machine.name}?",
            parameters: [Parlour::RbiGenerator::Parameter.new("state", type: "T.any(String, Symbol)")],
            return_type: "T::Boolean"
          )
        end

        def define_event_helpers(instance_module, machine)
          events_attribute = machine.attribute(:events).to_s
          transitions_attribute = machine.attribute(:transitions).to_s
          event_attribute = machine.attribute(:event).to_s
          event_transition_attribute = machine.attribute(:event_transition).to_s

          create_method(
            instance_module,
            events_attribute,
            parameters: [Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped")],
            return_type: "T::Array[T.any(String, Symbol)]"
          )
          create_method(
            instance_module,
            transitions_attribute,
            parameters: [Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped")],
            return_type: "T::Array[::StateMachines::Transition]"
          )
          create_method(
            instance_module,
            "fire_#{event_attribute}",
            parameters: [
              Parlour::RbiGenerator::Parameter.new("event", type: "T.any(String, Symbol)"),
              Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped"),
            ],
            return_type: "T::Boolean"
          )
          if machine.action
            create_method(
              instance_module,
              event_attribute,
              return_type: "T.nilable(Symbol)"
            )
            create_method(
              instance_module,
              "#{event_attribute}=",
              parameters: [Parlour::RbiGenerator::Parameter.new("value", type: "T.any(String, Symbol)")],
              return_type: "T.any(String, Symbol)"
            )
            create_method(
              instance_module,
              event_transition_attribute,
              return_type: "T.nilable(::StateMachines::Transition)"
            )
            create_method(
              instance_module,
              "#{event_transition_attribute}=",
              parameters: [Parlour::RbiGenerator::Parameter.new("value", type: "::StateMachines::Transition")],
              return_type: "::StateMachines::Transition"
            )
          end
        end

        def define_path_helpers(instance_module, machine)
          paths_attribute = machine.attribute(:paths).to_s

          create_method(
            instance_module,
            paths_attribute,
            parameters: [Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped")],
            return_type: "T::Array[::StateMachines::Transition]"
          )
        end

        def define_name_helpers(instance_module, class_module, machine)
          name_attribute = machine.attribute(:name).to_s
          event_name_attribute = machine.attribute(:event_name).to_s

          create_method(
            class_module,
            "human_#{name_attribute}",
            parameters: [Parlour::RbiGenerator::Parameter.new("state", type: "T.any(String, Symbol)")],
            return_type: "String"
          )
          create_method(
            class_module,
            "human_#{event_name_attribute}",
            parameters: [Parlour::RbiGenerator::Parameter.new("event", type: "T.any(String, Symbol)")],
            return_type: "String"
          )
          create_method(
            instance_module,
            name_attribute,
            return_type: "T.any(String, Symbol)"
          )
          create_method(
            instance_module,
            "human_#{name_attribute}",
            return_type: "String"
          )
        end

        def define_scopes(class_module, machine)
          helper_modules = machine.instance_variable_get(:@helper_modules)
          class_methods = helper_modules[:class].instance_methods(false)

          class_methods
            .select { |method| method.start_with?("with_", "without_") }
            .each do |method|
              create_method(
                class_module,
                method.to_s,
                parameters: [Parlour::RbiGenerator::Parameter.new("*states", type: "T.any(String, Symbol)")],
                return_type: "T.untyped"
              )
            end
        end
      end
    end
  end
end