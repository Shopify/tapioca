# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    class Pipeline
      extend T::Sig

      sig { returns(T::Enumerable[T.class_of(Compiler)]) }
      attr_reader :active_compilers

      sig { returns(T::Array[Module]) }
      attr_reader :requested_constants

      sig { returns(T.proc.params(error: String).void) }
      attr_reader :error_handler

      sig { returns(T::Array[String]) }
      attr_reader :errors

      sig do
        params(
          requested_constants: T::Array[Module],
          requested_compilers: T::Array[T.class_of(Compiler)],
          excluded_compilers: T::Array[T.class_of(Compiler)],
          error_handler: T.proc.params(error: String).void,
          number_of_workers: T.nilable(Integer),
        ).void
      end
      def initialize(
        requested_constants:,
        requested_compilers: [],
        excluded_compilers: [],
        error_handler: $stderr.method(:puts).to_proc,
        number_of_workers: nil
      )
        @active_compilers = T.let(
          gather_active_compilers(requested_compilers, excluded_compilers),
          T::Enumerable[T.class_of(Compiler)]
        )
        @requested_constants = requested_constants
        @error_handler = error_handler
        @number_of_workers = number_of_workers
        @errors = T.let([], T::Array[String])
      end

      sig do
        type_parameters(:T).params(
          blk: T.proc.params(constant: Module, rbi: RBI::File).returns(T.type_parameter(:T))
        ).returns(T::Array[T.type_parameter(:T)])
      end
      def run(&blk)
        constants_to_process = gather_constants(requested_constants)
          .select { |c| Module === c } # Filter value constants out
          .sort_by! { |c| T.must(Runtime::Reflection.name_of(c)) }

        if constants_to_process.empty?
          report_error(<<~ERROR)
            No classes/modules can be matched for RBI generation.
            Please check that the requested classes/modules include processable DSL methods.
          ERROR
        end

        result = Executor.new(
          constants_to_process,
          number_of_workers: @number_of_workers
        ).run_in_parallel do |constant|
          rbi = rbi_for_constant(constant)
          next if rbi.nil?

          blk.call(constant, rbi)
        end

        errors.each do |msg|
          report_error(msg)
        end

        result.compact
      end

      sig { params(error: String).void }
      def add_error(error)
        @errors << error
      end

      sig { params(compiler_name: String).returns(T::Boolean) }
      def compiler_enabled?(compiler_name)
        potential_names = Compilers::NAMESPACES.map { |namespace| namespace + compiler_name }

        active_compilers.any? do |compiler|
          potential_names.any?(compiler.name)
        end
      end

      sig { returns(T::Array[T.class_of(Compiler)]) }
      def compilers
        @compilers = T.let(@compilers, T.nilable(T::Array[T.class_of(Compiler)]))
        @compilers ||= Runtime::Reflection.descendants_of(Compiler).sort_by do |compiler|
          T.must(compiler.name)
        end
      end

      private

      sig do
        params(
          requested_compilers: T::Array[T.class_of(Compiler)],
          excluded_compilers: T::Array[T.class_of(Compiler)]
        ).returns(T::Enumerable[T.class_of(Compiler)])
      end
      def gather_active_compilers(requested_compilers, excluded_compilers)
        active_compilers = compilers
        active_compilers -= excluded_compilers
        active_compilers &= requested_compilers unless requested_compilers.empty?
        active_compilers
      end

      sig { params(requested_constants: T::Array[Module]).returns(T::Set[Module]) }
      def gather_constants(requested_constants)
        constants = active_compilers.map(&:processable_constants).reduce(Set.new, :union)
        constants = filter_anonymous_and_reloaded_constants(constants)

        constants &= requested_constants unless requested_constants.empty?
        constants
      end

      sig { params(constants: T::Set[Module]).returns(T::Set[Module]) }
      def filter_anonymous_and_reloaded_constants(constants)
        # Group constants by their names
        constants_by_name = constants
          .group_by { |c| T.must(Runtime::Reflection.name_of(c)) }
          .select { |name, _| !name.nil? }

        # Find the constants that have been reloaded
        reloaded_constants = constants_by_name.select { |_, constants| constants.size > 1 }.keys

        unless reloaded_constants.empty?
          reloaded_constant_names = reloaded_constants.map { |name| "`#{name}`" }.join(", ")

          $stderr.puts("WARNING: Multiple constants with the same name: #{reloaded_constant_names}")
          $stderr.puts("Make sure some object is not holding onto these constants during an app reload.")
        end

        # Look up all the constants back from their names. The resulting constant set will be the
        # set of constants that are actually in memory with those names.
        constants_by_name
          .keys
          .map { |name| T.cast(Runtime::Reflection.constantize(name), Module) }
          .select { |mod| Runtime::Reflection.constant_defined?(mod) }
          .to_set
      end

      sig { params(constant: Module).returns(T.nilable(RBI::File)) }
      def rbi_for_constant(constant)
        file = RBI::File.new(strictness: "true")

        active_compilers.each do |compiler_class|
          next unless compiler_class.handles?(constant)

          compiler = compiler_class.new(self, file.root, constant)
          compiler.decorate
        rescue
          $stderr.puts("Error: `#{compiler_class.name}` failed to generate RBI for `#{constant}`")
          raise # This is an unexpected error, so re-raise it
        end

        return if file.root.empty?

        file
      end

      sig { params(error: String).returns(T.noreturn) }
      def report_error(error)
        handler = error_handler
        handler.call(error)
        exit(1)
      end
    end
  end
end
