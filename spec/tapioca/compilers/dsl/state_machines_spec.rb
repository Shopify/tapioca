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

      with_content(content) do
        expect(subject.processable_constants).to(eq(Set.new([Vehicle, User])))
      end
    end
  end

  describe("#decorate") do
    def rbi_for(content)
      with_content(content) do
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        subject.decorate(parlour.root, Vehicle)
        parlour.rbi
      end
    end

    it(" generate RBI for a classe with state_machine, verify state accessor methods") do
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
      expect(rbi_for(content)).to(eq(expected))
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
      expect(rbi_for(content)).to(include(expected))
    end

    it(" generate RBI for a classe with state_machine, verify path, event and state helper methods ") do
      content = <<~RUBY
        class Vehicle
          state_machine :alarm_state, initial: :active, namespace: :'alarm' do
            state :active, :value => 1
            state :off, :value => 0
          end
        end

      RUBY
      expected = <<~RUBY
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
      expect(rbi_for(content)).to(include(expected))
    end

    it("generate RBI for a classe with state_machine, verify path helper method only ") do
      content = <<~RUBY
        class Vehicle
          attr_accessor :seatbelt_on, :time_used, :auto_shop_busy

          state_machine :state, initial: :parked do
            before_transition parked: any - :parked, do: :put_on_seatbelt
          end
        end
      RUBY

      expected = <<~RUBY
        sig { params(args: T.untyped).returns(T::Array[::StateMachines::Transition]) }
          def state_paths(*args); end
      RUBY
      expect(rbi_for(content)).to(include(expected))
    end

    it(" generate RBI for a class with state_machine, verify helper methods start with_ and without") do
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
      expect(rbi_for(content)).to(include(expected))
    end

    it("generate RBI for a class with state_machine, verify helper method for machine.action ") do
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
      expect(rbi_for(content)).to(include(expected))
    end
  end
end
