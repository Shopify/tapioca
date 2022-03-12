# typed: strict
# frozen_string_literal: true

require "tapioca/dsl/compilers"

module Tapioca
  module Dsl
    class Pipeline
      extend T::Sig

      sig { returns(T::Enumerable[T.class_of(Compiler)]) }
      attr_reader :compilers

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
        @compilers = T.let(
          gather_compilers(requested_compilers, excluded_compilers),
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
          .select { |c| Runtime::Reflection.name_of(c) && Module === c } # Filter anonymous or value constants
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

        @compilers.any? do |compiler|
          potential_names.any?(compiler.name)
        end
      end

      private

      sig do
        params(
          requested_compilers: T::Array[T.class_of(Compiler)],
          excluded_compilers: T::Array[T.class_of(Compiler)]
        ).returns(T::Enumerable[T.class_of(Compiler)])
      end
      def gather_compilers(requested_compilers, excluded_compilers)
        Runtime::Reflection.descendants_of(Compiler).select do |klass|
          (requested_compilers.empty? || requested_compilers.include?(klass)) &&
            !excluded_compilers.include?(klass)
        end.sort_by { |klass| T.must(klass.name) }
      end

      sig { params(requested_constants: T::Array[Module]).returns(T::Set[Module]) }
      def gather_constants(requested_constants)
        constants = compilers.map(&:processable_constants).reduce(Set.new, :union)
        constants &= requested_constants unless requested_constants.empty?
        constants
      end

      sig { params(constant: Module).returns(T.nilable(RBI::File)) }
      def rbi_for_constant(constant)
        file = RBI::File.new(strictness: "true")

        compilers.each do |compiler_class|
          next unless compiler_class.handles?(constant)

          compiler = compiler_class.new(self, file.root, constant)
          compiler.decorate
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
