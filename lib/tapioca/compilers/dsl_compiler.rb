# typed: strict
# frozen_string_literal: true

require "tapioca/compilers/dsl/base"

module Tapioca
  module Compilers
    class DslCompiler
      extend T::Sig

      sig { returns(T::Enumerable[Dsl::Base]) }
      attr_reader :generators

      sig { returns(T::Array[Module]) }
      attr_reader :requested_constants

      sig { returns(T.proc.params(error: String).void) }
      attr_reader :error_handler

      sig do
        params(
          requested_constants: T::Array[Module],
          requested_generators: T::Array[T.class_of(Dsl::Base)],
          excluded_generators: T::Array[T.class_of(Dsl::Base)],
          error_handler: T.nilable(T.proc.params(error: String).void)
        ).void
      end
      def initialize(requested_constants:, requested_generators: [], excluded_generators: [], error_handler: nil)
        @generators = T.let(
          gather_generators(requested_generators, excluded_generators),
          T::Enumerable[Dsl::Base]
        )
        @requested_constants = requested_constants
        @error_handler = T.let(error_handler || $stderr.method(:puts), T.proc.params(error: String).void)
      end

      sig { params(blk: T.proc.params(constant: Module, rbi: String).void).void }
      def run(&blk)
        constants_to_process = gather_constants(requested_constants)

        if constants_to_process.empty?
          report_error(<<~ERROR)
            No classes/modules can be matched for RBI generation.
            Please check that the requested classes/modules include processable DSL methods.
          ERROR
        end

        constants_to_process.sort_by { |c| c.name.to_s }.each do |constant|
          rbi = rbi_for_constant(constant)
          next if rbi.nil?

          blk.call(constant, rbi)
        end
      end

      private

      sig do
        params(
          requested_generators: T::Array[T.class_of(Dsl::Base)],
          excluded_generators: T::Array[T.class_of(Dsl::Base)]
        ).returns(T::Enumerable[Dsl::Base])
      end
      def gather_generators(requested_generators, excluded_generators)
        generator_klasses = Dsl::Base.descendants.select do |klass|
          (requested_generators.empty? || requested_generators.include?(klass)) &&
            !excluded_generators.include?(klass)
        end

        T.cast(generator_klasses.map(&:new), T::Enumerable[Dsl::Base])
      end

      sig { params(requested_constants: T::Array[Module]).returns(T::Set[Module]) }
      def gather_constants(requested_constants)
        constants = generators.map(&:processable_constants).reduce(Set.new, :union)
        constants &= requested_constants unless requested_constants.empty?
        constants
      end

      sig { params(constant: Module).returns(T.nilable(String)) }
      def rbi_for_constant(constant)
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)

        generators.each do |generator|
          next unless generator.handles?(constant)
          generator.decorate(parlour.root, constant)
        end

        return if parlour.root.children.empty?

        resolve_conflicts(parlour)

        parlour.rbi("true").strip
      end

      sig { params(parlour: Parlour::RbiGenerator).void }
      def resolve_conflicts(parlour)
        Parlour::ConflictResolver.new.resolve_conflicts(parlour.root) do |msg, candidates|
          error = StringIO.new
          error.puts "=== Error ==="
          error.puts msg
          error.puts "# Candidates"
          candidates.each_with_index do |candidate, index|
            error.puts "  #{index}. #{candidate.describe}"
          end
          report_error(error.string)
        end
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
