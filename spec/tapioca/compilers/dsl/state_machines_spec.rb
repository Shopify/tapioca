# typed: false
# frozen_string_literal: true

require "spec_helper"
require "tapioca/compilers/dsl/smart_properties"
RSpec.describe(Tapioca::Compilers::Dsl::StateMachines) do
  describe("#initialize") do
    it("gathers no constants if there are no StateMachines classes") do
      expect(subject.processable_constants).to(be_empty)
    end

    it("gathers only StateMachines classes") do
      content = <<~RUBY
        class Vehicle
          state_machine
        end

        class User
          state_machine
        end

        class Comment
        end
      RUBY

      with_contents(content) do
        expect(subject.processable_constants).to(eq(Set.new([Vehicle, User])))
      end
    end
  end

  describe("#decorate") do
    let(:output) do
      parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
      subject.decorate(parlour.root, Vehicle)
      parlour.rbi
    end


    it(" generate RBI for classes with state_machines with event and state") do
      content = <<~RUBY
        class Vehicle
          state_machine :alarm_state, initial: :active, namespace: :'alarm' do
            event :enable do
              transition all => :active
            end

            event :disable do
              transition all => :off
            end

            state :active, :value => 1
            state :off, :value => 0
          end
        end

      RUBY
      expected = <<~RUBY
        # typed: strong
        class Vehicle
          include Vehicle::StateMachineInstanceHelperModule
          extend Vehicle::StateMachineClassHelperModule
        end

        module Vehicle::StateMachineClassHelperModule
          sig { params(event: T.any(String, Symbol)).returns(String) }
          def human_alarm_state_event_name(event); end

          sig { params(state: T.any(String, Symbol)).returns(String) }
          def human_alarm_state_name(state); end
        end

        module Vehicle::StateMachineInstanceHelperModule
          sig { returns(T::Boolean) }
          def alarm_active?; end

          sig { returns(T::Boolean) }
          def alarm_off?; end

          sig { returns(Integer) }
          def alarm_state; end

          sig { params(value: Integer).returns(Integer) }
          def alarm_state=(value); end

          sig { params(state: T.any(String, Symbol)).returns(T::Boolean) }
          def alarm_state?(state); end

          sig { params(args: T.untyped).returns(T::Array[T.any(String, Symbol)]) }
          def alarm_state_events(*args); end

          sig { returns(T.any(String, Symbol)) }
          def alarm_state_name; end

          sig { params(args: T.untyped).returns(T::Array[::StateMachines::Transition]) }
          def alarm_state_paths(*args); end

          sig { params(args: T.untyped).returns(T::Array[::StateMachines::Transition]) }
          def alarm_state_transitions(*args); end

          sig { returns(T::Boolean) }
          def can_disable_alarm?; end

          sig { returns(T::Boolean) }
          def can_enable_alarm?; end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def disable_alarm(*args); end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def disable_alarm!(*args); end

          sig { params(args: T.untyped).returns(T.nilable(::StateMachines::Transition)) }
          def disable_alarm_transition(*args); end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def enable_alarm(*args); end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def enable_alarm!(*args); end

          sig { params(args: T.untyped).returns(T.nilable(::StateMachines::Transition)) }
          def enable_alarm_transition(*args); end

          sig { params(event: T.any(String, Symbol), args: T.untyped).returns(T::Boolean) }
          def fire_alarm_state_event(event, *args); end

          sig { returns(String) }
          def human_alarm_state_name; end
        end
      RUBY
      with_contents(content) do
        expect(output).to(eq(expected))
      end
    end

    it("generate RBI for a class with state_machine, to verify helpers methods start with human_") do
      content = <<~RUBY
        class Vehicle
          state_machine :alarm_state, initial: :active, namespace: :'alarm' do
            event :enable do
              transition [:active, :on, :off] => :active
            end

            event :disable do
              transition active: :off
            end
          end
        end
      RUBY

      expected = <<~RUBY
        class Vehicle
          include Vehicle::StateMachineInstanceHelperModule
          extend Vehicle::StateMachineClassHelperModule
        end

        module Vehicle::StateMachineClassHelperModule
          sig { params(event: T.any(String, Symbol)).returns(String) }
          def human_alarm_state_event_name(event); end

          sig { params(state: T.any(String, Symbol)).returns(String) }
          def human_alarm_state_name(state); end
        end
      RUBY

      with_contents(content) do
        expect(output).to include(expected)
      end
    end

    it(" generate RBI for classes with state_machines with only states and no transition defined ") do
      content = <<~RUBY
        class Vehicle
          state_machine :alarm_state, initial: :active, namespace: :'alarm' do
            state :active, :value => 1
            state :off, :value => 0
          end
        end

      RUBY
      expected = <<~RUBY
        # typed: strong
        class Vehicle
          include Vehicle::StateMachineInstanceHelperModule
          extend Vehicle::StateMachineClassHelperModule
        end

        module Vehicle::StateMachineClassHelperModule
          sig { params(event: T.any(String, Symbol)).returns(String) }
          def human_alarm_state_event_name(event); end

          sig { params(state: T.any(String, Symbol)).returns(String) }
          def human_alarm_state_name(state); end
        end

        module Vehicle::StateMachineInstanceHelperModule
          sig { returns(T::Boolean) }
          def alarm_active?; end

          sig { returns(T::Boolean) }
          def alarm_off?; end

          sig { returns(Integer) }
          def alarm_state; end

          sig { params(value: Integer).returns(Integer) }
          def alarm_state=(value); end

          sig { params(state: T.any(String, Symbol)).returns(T::Boolean) }
          def alarm_state?(state); end

          sig { params(args: T.untyped).returns(T::Array[T.any(String, Symbol)]) }
          def alarm_state_events(*args); end

          sig { returns(T.any(String, Symbol)) }
          def alarm_state_name; end

          sig { params(args: T.untyped).returns(T::Array[::StateMachines::Transition]) }
          def alarm_state_paths(*args); end

          sig { params(args: T.untyped).returns(T::Array[::StateMachines::Transition]) }
          def alarm_state_transitions(*args); end

          sig { params(event: T.any(String, Symbol), args: T.untyped).returns(T::Boolean) }
          def fire_alarm_state_event(event, *args); end

          sig { returns(String) }
          def human_alarm_state_name; end
        end
      RUBY
      with_contents(content) do
        expect(output).to(eq(expected))
      end
    end

    it("generate RBI for classes with state_machines with more transitions, more states and more events") do
      content = <<~RUBY
        class Vehicle
          attr_accessor :seatbelt_on, :time_used, :auto_shop_busy

          state_machine :state, initial: :parked do
            before_transition parked: any - :parked, do: :put_on_seatbelt

            after_transition on: :crash, do: :tow
            after_transition on: :repair, do: :fix
            after_transition any => :parked do |vehicle, transition|
              vehicle.seatbelt_on = false
            end

            after_failure on: :ignite, do: :log_start_failure

            around_transition do |vehicle, transition, block|
              start = Time.now
              block.call
              vehicle.time_used += Time.now - start
            end

            event :park do
              transition [:idling, :first_gear] => :parked
            end

            event :ignite do
              transition stalled: same, parked: :idling
            end

            event :idle do
              transition first_gear: :idling
            end

            event :shift_up do
              transition idling: :first_gear, first_gear: :second_gear, second_gear: :third_gear
            end

            event :shift_down do
              transition third_gear: :second_gear, second_gear: :first_gear
            end

            event :crash do
              transition all - [:parked, :stalled] => :stalled, if: ->(vehicle) {!vehicle.passed_inspection?}
            end

            event :repair do
              # The first transition that matches the state and passes its conditions
              # will be used
              transition stalled: :parked, unless: :auto_shop_busy
              transition stalled: same
            end

            state :parked do
              def speed
                0
              end
            end

            state :idling, :first_gear do
              def speed
                10
              end
            end

            state all - [:parked, :stalled, :idling] do
              def moving?
                true
              end
            end

            state :parked, :stalled, :idling do
              def moving?
                false
              end
            end
          end
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Vehicle
          include Vehicle::StateMachineInstanceHelperModule
          extend Vehicle::StateMachineClassHelperModule
        end

        module Vehicle::StateMachineClassHelperModule
          sig { params(event: T.any(String, Symbol)).returns(String) }
          def human_state_event_name(event); end

          sig { params(state: T.any(String, Symbol)).returns(String) }
          def human_state_name(state); end
        end

        module Vehicle::StateMachineInstanceHelperModule
          sig { returns(T::Boolean) }
          def can_crash?; end

          sig { returns(T::Boolean) }
          def can_idle?; end

          sig { returns(T::Boolean) }
          def can_ignite?; end

          sig { returns(T::Boolean) }
          def can_park?; end

          sig { returns(T::Boolean) }
          def can_repair?; end

          sig { returns(T::Boolean) }
          def can_shift_down?; end

          sig { returns(T::Boolean) }
          def can_shift_up?; end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def crash(*args); end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def crash!(*args); end

          sig { params(args: T.untyped).returns(T.nilable(::StateMachines::Transition)) }
          def crash_transition(*args); end

          sig { params(event: T.any(String, Symbol), args: T.untyped).returns(T::Boolean) }
          def fire_state_event(event, *args); end

          sig { returns(T::Boolean) }
          def first_gear?; end

          sig { returns(String) }
          def human_state_name; end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def idle(*args); end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def idle!(*args); end

          sig { params(args: T.untyped).returns(T.nilable(::StateMachines::Transition)) }
          def idle_transition(*args); end

          sig { returns(T::Boolean) }
          def idling?; end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def ignite(*args); end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def ignite!(*args); end

          sig { params(args: T.untyped).returns(T.nilable(::StateMachines::Transition)) }
          def ignite_transition(*args); end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def park(*args); end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def park!(*args); end

          sig { params(args: T.untyped).returns(T.nilable(::StateMachines::Transition)) }
          def park_transition(*args); end

          sig { returns(T::Boolean) }
          def parked?; end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def repair(*args); end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def repair!(*args); end

          sig { params(args: T.untyped).returns(T.nilable(::StateMachines::Transition)) }
          def repair_transition(*args); end

          sig { returns(T::Boolean) }
          def second_gear?; end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def shift_down(*args); end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def shift_down!(*args); end

          sig { params(args: T.untyped).returns(T.nilable(::StateMachines::Transition)) }
          def shift_down_transition(*args); end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def shift_up(*args); end

          sig { params(args: T.untyped).returns(T::Boolean) }
          def shift_up!(*args); end

          sig { params(args: T.untyped).returns(T.nilable(::StateMachines::Transition)) }
          def shift_up_transition(*args); end

          sig { returns(T::Boolean) }
          def stalled?; end

          sig { returns(String) }
          def state; end

          sig { params(value: String).returns(String) }
          def state=(value); end

          sig { params(state: T.any(String, Symbol)).returns(T::Boolean) }
          def state?(state); end

          sig { params(args: T.untyped).returns(T::Array[T.any(String, Symbol)]) }
          def state_events(*args); end

          sig { returns(T.any(String, Symbol)) }
          def state_name; end

          sig { params(args: T.untyped).returns(T::Array[::StateMachines::Transition]) }
          def state_paths(*args); end

          sig { params(args: T.untyped).returns(T::Array[::StateMachines::Transition]) }
          def state_transitions(*args); end

          sig { returns(T::Boolean) }
          def third_gear?; end
        end
      RUBY

      with_contents(content) do
        expect(output).to(eq(expected))
      end
    end

    it(" generate RBI for classe with state_machines with methods start with_ and without") do
      content = <<~RUBY

      module CustomAttributeIntegration
        include StateMachines::Integrations::Base
        def self.integration_name
          :custom_attribute
        end

        def create_with_scope(_name)
          -> {}
        end
        def create_without_scope(_name)
          -> {}
        end
      end
      StateMachines::Integrations.register(CustomAttributeIntegration)
      class Vehicle
        state_machine :state, integration: :custom_attribute
      end
      RUBY

      expected = <<~RUBY
        sig { params(states: T.any(String, Symbol)).returns(T.untyped) }
          def with_state(*states); end

          sig { params(states: T.any(String, Symbol)).returns(T.untyped) }
          def with_states(*states); end

          sig { params(states: T.any(String, Symbol)).returns(T.untyped) }
          def without_state(*states); end

          sig { params(states: T.any(String, Symbol)).returns(T.untyped) }
          def without_states(*states); end
      RUBY

      with_contents(content) do
        expect(output).to include(expected)
      end
    end

    it("generate RBI for class with state_machines with action") do
      content = <<~RUBY

      module CustomAttributeIntegration
        include StateMachines::Integrations::Base
        def self.integration_name
          :custom_attribute
        end
        @defaults = { action: :save, use_transactions: false }
      end
      StateMachines::Integrations.register(CustomAttributeIntegration)
      class Vehicle
        state_machine :state, integration: :custom_attribute
      end
      RUBY

      expected = <<~RUBY
        sig { returns(T.nilable(Symbol)) }
          def state_event; end

          sig { params(value: T.any(String, Symbol)).returns(T.any(String, Symbol)) }
          def state_event=(value); end

          sig { returns(T.nilable(::StateMachines::Transition)) }
          def state_event_transition; end

          sig { params(value: ::StateMachines::Transition).returns(::StateMachines::Transition) }
          def state_event_transition=(value); end
      RUBY

      with_contents(content) do
        expect(output).to include(expected)
      end
    end
  end
end
