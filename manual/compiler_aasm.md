## AASM

`Tapioca::Dsl::Compilers::AASM` generate types for AASM state machines.
This gem dynamically defines constants and methods at runtime. For
example, given a class:

  class MyClass
    include AASM

    aasm do
      state :sleeping, initial: true
      state :running, :cleaning

      event :run do
        transitions from: :sleeping, to: :running
      end
    end
  end

This will result in the following constants being defined:

  STATE_SLEEPING, STATE_RUNNING, STATE_CLEANING

and the following methods being defined:

  sleeping?, running?, cleaning?
  run, run!, run_without_validation!, may_run?
