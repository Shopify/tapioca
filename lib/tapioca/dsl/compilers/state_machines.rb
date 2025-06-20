# typed: strict
# frozen_string_literal: true

return unless defined?(StateMachines)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::StateMachines` generates RBI files for classes that setup a
      # [`state_machine`](https://github.com/state-machines/state_machines). The compiler also
      # processes the extra methods generated by
      # [StateMachines Active Record](https://github.com/state-machines/state_machines-activerecord)
      # and [StateMachines Active Model](https://github.com/state-machines/state_machines-activemodel)
      # integrations.
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
      # this compiler will produce the RBI file `vehicle.rbi` with the following content:
      #
      # ~~~rbi
      # # vehicle.rbi
      # # typed: true
      # class Vehicle
      #   include StateMachineInstanceHelperModule
      #   extend StateMachineClassHelperModule
      #
      #   module StateMachineClassHelperModule
      #     sig { params(event: T.any(String, Symbol)).returns(String) }
      #     def human_alarm_state_event_name(event); end
      #
      #     sig { params(state: T.any(String, Symbol)).returns(String) }
      #     def human_alarm_state_name(state); end
      #   end
      #
      #   module StateMachineInstanceHelperModule
      #     sig { returns(T::Boolean) }
      #     def alarm_active?; end
      #
      #     sig { returns(T::Boolean) }
      #     def alarm_off?; end
      #
      #     sig { returns(Integer) }
      #     def alarm_state; end
      #
      #     sig { params(value: Integer).returns(Integer) }
      #     def alarm_state=(value); end
      #
      #     sig { params(state: T.any(String, Symbol)).returns(T::Boolean) }
      #     def alarm_state?(state); end
      #
      #     sig { params(args: T.untyped).returns(T::Array[T.any(String, Symbol)]) }
      #     def alarm_state_events(*args); end
      #
      #     sig { returns(T.any(String, Symbol)) }
      #     def alarm_state_name; end
      #
      #     sig { params(args: T.untyped).returns(T::Array[::StateMachines::Transition]) }
      #     def alarm_state_paths(*args); end
      #
      #     sig { params(args: T.untyped).returns(T::Array[::StateMachines::Transition]) }
      #     def alarm_state_transitions(*args); end
      #
      #     sig { returns(T::Boolean) }
      #     def can_disable_alarm?; end
      #
      #     sig { returns(T::Boolean) }
      #     def can_enable_alarm?; end
      #
      #     sig { params(args: T.untyped).returns(T::Boolean) }
      #     def disable_alarm(*args); end
      #
      #     sig { params(args: T.untyped).returns(T::Boolean) }
      #     def disable_alarm!(*args); end
      #
      #     sig { params(args: T.untyped).returns(T.nilable(::StateMachines::Transition)) }
      #     def disable_alarm_transition(*args); end
      #
      #     sig { params(args: T.untyped).returns(T::Boolean) }
      #     def enable_alarm(*args); end
      #
      #     sig { params(args: T.untyped).returns(T::Boolean) }
      #     def enable_alarm!(*args); end
      #
      #     sig { params(args: T.untyped).returns(T.nilable(::StateMachines::Transition)) }
      #     def enable_alarm_transition(*args); end
      #
      #     sig { params(event: T.any(String, Symbol), args: T.untyped).returns(T::Boolean) }
      #     def fire_alarm_state_event(event, *args); end
      #
      #     sig { returns(String) }
      #     def human_alarm_state_name; end
      #   end
      # end
      # ~~~
      #: [ConstantType = (Module & ::StateMachines::ClassMethods)]
      class StateMachines < Compiler
        extend T::Sig

        # @override
        #: -> void
        def decorate
          return if constant.state_machines.empty?

          root.create_path(T.unsafe(constant)) do |klass|
            instance_module_name = "StateMachineInstanceHelperModule"
            class_module_name = "StateMachineClassHelperModule"

            instance_module = RBI::Module.new(instance_module_name)
            klass << instance_module

            class_module = RBI::Module.new(class_module_name)
            klass << class_module

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

            klass.create_include(instance_module_name)
            klass.create_extend(class_module_name)
          end
        end

        class << self
          extend T::Sig

          # @override
          #: -> T::Enumerable[Module]
          def gather_constants
            all_classes.select { |mod| ::StateMachines::InstanceMethods > mod }
          end
        end

        private

        #: (::StateMachines::Machine machine) -> String
        def state_type_for(machine)
          value_types = machine.states.map { |state| state.value.class.name }.uniq

          if value_types.size == 1
            value_types.first
          else
            "T.any(#{value_types.join(", ")})"
          end
        end

        #: (RBI::Module instance_module) -> void
        def define_activerecord_methods(instance_module)
          instance_module.create_method(
            "changed_for_autosave?",
            return_type: "T::Boolean",
          )
        end

        #: (RBI::Module instance_module, ::StateMachines::Machine machine) -> void
        def define_state_methods(instance_module, machine)
          machine.states.each do |state|
            instance_module.create_method(
              "#{state.qualified_name}?",
              return_type: "T::Boolean",
            )
          end
        end

        #: (RBI::Module instance_module, ::StateMachines::Machine machine) -> void
        def define_event_methods(instance_module, machine)
          machine.events.each do |event|
            instance_module.create_method(
              "can_#{event.qualified_name}?",
              return_type: "T::Boolean",
            )
            instance_module.create_method(
              "#{event.qualified_name}_transition",
              parameters: [create_rest_param("args", type: "T.untyped")],
              return_type: "T.nilable(::StateMachines::Transition)",
            )
            instance_module.create_method(
              event.qualified_name.to_s,
              parameters: [create_rest_param("args", type: "T.untyped")],
              return_type: "T::Boolean",
            )
            instance_module.create_method(
              "#{event.qualified_name}!",
              parameters: [create_rest_param("args", type: "T.untyped")],
              return_type: "T::Boolean",
            )
          end
        end

        #: (RBI::Module instance_module, ::StateMachines::Machine machine, String state_type) -> void
        def define_state_accessor(instance_module, machine, state_type)
          attribute = machine.attribute.to_s
          instance_module.create_method(
            attribute,
            return_type: state_type,
          ) if ::StateMachines::HelperModule === machine.owner_class.instance_method(attribute).owner
          instance_module.create_method(
            "#{attribute}=",
            parameters: [create_param("value", type: state_type)],
            return_type: state_type,
          ) if ::StateMachines::HelperModule === machine.owner_class.instance_method("#{attribute}=").owner
        end

        #: (RBI::Module instance_module, ::StateMachines::Machine machine) -> void
        def define_state_predicate(instance_module, machine)
          instance_module.create_method(
            "#{machine.name}?",
            parameters: [create_param("state", type: "T.any(String, Symbol)")],
            return_type: "T::Boolean",
          )
        end

        #: (RBI::Module instance_module, ::StateMachines::Machine machine) -> void
        def define_event_helpers(instance_module, machine)
          events_attribute = machine.attribute(:events).to_s
          transitions_attribute = machine.attribute(:transitions).to_s
          event_attribute = machine.attribute(:event).to_s
          event_transition_attribute = machine.attribute(:event_transition).to_s

          instance_module.create_method(
            events_attribute,
            parameters: [create_rest_param("args", type: "T.untyped")],
            return_type: "T::Array[T.any(String, Symbol)]",
          )
          instance_module.create_method(
            transitions_attribute,
            parameters: [create_rest_param("args", type: "T.untyped")],
            return_type: "T::Array[::StateMachines::Transition]",
          )
          instance_module.create_method(
            "fire_#{event_attribute}",
            parameters: [
              create_param("event", type: "T.any(String, Symbol)"),
              create_rest_param("args", type: "T.untyped"),
            ],
            return_type: "T::Boolean",
          )
          if machine.action
            instance_module.create_method(
              event_attribute,
              return_type: "T.nilable(Symbol)",
            )
            instance_module.create_method(
              "#{event_attribute}=",
              parameters: [create_param("value", type: "T.any(String, Symbol)")],
              return_type: "T.any(String, Symbol)",
            )
            instance_module.create_method(
              event_transition_attribute,
              return_type: "T.nilable(::StateMachines::Transition)",
            )
            instance_module.create_method(
              "#{event_transition_attribute}=",
              parameters: [create_param("value", type: "::StateMachines::Transition")],
              return_type: "::StateMachines::Transition",
            )
          end
        end

        #: (RBI::Module instance_module, ::StateMachines::Machine machine) -> void
        def define_path_helpers(instance_module, machine)
          paths_attribute = machine.attribute(:paths).to_s

          instance_module.create_method(
            paths_attribute,
            parameters: [create_rest_param("args", type: "T.untyped")],
            return_type: "T::Array[::StateMachines::Transition]",
          )
        end

        #: (RBI::Module instance_module, RBI::Module class_module, ::StateMachines::Machine machine) -> void
        def define_name_helpers(instance_module, class_module, machine)
          name_attribute = machine.attribute(:name).to_s
          event_name_attribute = machine.attribute(:event_name).to_s

          class_module.create_method(
            "human_#{name_attribute}",
            parameters: [create_param("state", type: "T.any(String, Symbol)")],
            return_type: "String",
          )
          class_module.create_method(
            "human_#{event_name_attribute}",
            parameters: [create_param("event", type: "T.any(String, Symbol)")],
            return_type: "String",
          )
          instance_module.create_method(
            name_attribute,
            return_type: "T.any(String, Symbol)",
          )
          instance_module.create_method(
            "human_#{name_attribute}",
            return_type: "String",
          )
        end

        #: (RBI::Module class_module, ::StateMachines::Machine machine) -> void
        def define_scopes(class_module, machine)
          helper_modules = machine.instance_variable_get(:@helper_modules)
          class_methods = helper_modules[:class].instance_methods(false)

          class_methods
            .select { |method| method.to_s.start_with?("with_", "without_") }
            .each do |method|
              class_module.create_method(
                method.to_s,
                parameters: [create_rest_param("states", type: "T.any(String, Symbol)")],
                return_type: "T.untyped",
              )
            end
        end
      end
    end
  end
end
