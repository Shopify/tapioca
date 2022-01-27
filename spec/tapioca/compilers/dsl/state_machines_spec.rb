# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::StateMachinesSpec < DslSpec
  describe("#initialize") do
    after do
      T.unsafe(self).assert_no_generated_errors
    end

    it "gathers no constants if there are no StateMachines classes" do
      assert_empty(gathered_constants)
    end

    it "gathers only StateMachines classes" do
      add_ruby_file("content.rb", <<~RUBY)
        class Vehicle
          state_machine
        end

        class User
          state_machine
        end

        class Comment
        end
      RUBY

      assert_equal(["User", "Vehicle"], gathered_constants)
    end
  end

  describe("#decorate") do
    after do
      T.unsafe(self).assert_no_generated_errors
    end

    it " generates an RBI that includes state accessor methods" do
      add_ruby_file("vehicle.rb", <<~RUBY)
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

      expected = <<~RBI
        # typed: strong

        class Vehicle
          include StateMachineInstanceHelperModule
          extend StateMachineClassHelperModule

          module StateMachineClassHelperModule
            sig { params(event: T.any(String, Symbol)).returns(String) }
            def human_alarm_state_event_name(event); end

            sig { params(state: T.any(String, Symbol)).returns(String) }
            def human_alarm_state_name(state); end
          end

          module StateMachineInstanceHelperModule
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
        end
      RBI

      assert_equal(expected, rbi_for(:Vehicle))
    end

    it "generates an RBI that includes name helpers methods" do
      add_ruby_file("vehicle.rb", <<~RUBY)
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

      expected = <<~RBI
        class Vehicle
          include StateMachineInstanceHelperModule
          extend StateMachineClassHelperModule

          module StateMachineClassHelperModule
            sig { params(event: T.any(String, Symbol)).returns(String) }
            def human_alarm_state_event_name(event); end

            sig { params(state: T.any(String, Symbol)).returns(String) }
            def human_alarm_state_name(state); end
          end
      RBI

      assert_includes(rbi_for(:Vehicle), expected)
    end

    it "generates an RBI with path, event and state helper methods" do
      add_ruby_file("vehicle.rb", <<~RUBY)
        class Vehicle
          state_machine :alarm_state, initial: :active, namespace: :'alarm' do
            state :active, :value => 1
            state :off, :value => 0
          end
        end
      RUBY

      expected = indented(<<~RBI, 2)
        module StateMachineInstanceHelperModule
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
      RBI

      assert_includes(rbi_for(:Vehicle), expected)
    end

    it "generates an RBI with path helper methods only" do
      add_ruby_file("vehicle.rb", <<~RUBY)
        class Vehicle
          attr_accessor :seatbelt_on, :time_used, :auto_shop_busy

          state_machine :state, initial: :parked do
            before_transition parked: any - :parked, do: :put_on_seatbelt
          end
        end
      RUBY

      expected = indented(<<~RBI, 4)
        sig { params(args: T.untyped).returns(T::Array[::StateMachines::Transition]) }
        def state_paths(*args); end
      RBI

      assert_includes(rbi_for(:Vehicle), expected)
    end

    it "generates an RBI with scope methods when state machine defines scopes" do
      add_ruby_file("custom_attribute_integration.rb", <<~RUBY)
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
      RUBY

      add_ruby_file("vehicle.rb", <<~RUBY)
        class Vehicle
          state_machine :state, integration: :custom_attribute
        end
      RUBY

      expected = indented(<<~RBI, 4)
        sig { params(states: T.any(String, Symbol)).returns(T.untyped) }
        def with_state(*states); end

        sig { params(states: T.any(String, Symbol)).returns(T.untyped) }
        def with_states(*states); end

        sig { params(states: T.any(String, Symbol)).returns(T.untyped) }
        def without_state(*states); end

        sig { params(states: T.any(String, Symbol)).returns(T.untyped) }
        def without_states(*states); end
      RBI

      assert_includes(rbi_for(:Vehicle), expected)
    end

    it "generates an RBI with action methods when state machine defines an action" do
      add_ruby_file("custom_attribute_integration.rb", <<~RUBY)
        module CustomAttributeIntegration
          include StateMachines::Integrations::Base
          def self.integration_name
            :custom_attribute
          end
          @defaults = { action: :save, use_transactions: false }
        end

        StateMachines::Integrations.register(CustomAttributeIntegration)
      RUBY

      add_ruby_file("vehicle.rb", <<~RUBY)
        class Vehicle
          state_machine :state, integration: :custom_attribute
        end
      RUBY

      expected = indented(<<~RBI, 4)
        sig { returns(T.nilable(Symbol)) }
        def state_event; end

        sig { params(value: T.any(String, Symbol)).returns(T.any(String, Symbol)) }
        def state_event=(value); end

        sig { returns(T.nilable(::StateMachines::Transition)) }
        def state_event_transition; end

        sig { params(value: ::StateMachines::Transition).returns(::StateMachines::Transition) }
        def state_event_transition=(value); end
      RBI

      assert_includes(rbi_for(:Vehicle), expected)
    end
  end
end
