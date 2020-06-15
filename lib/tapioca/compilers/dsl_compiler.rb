# frozen_string_literal: true
# typed: true

require "tapioca/compilers/dsl/base"

module Tapioca
  module Compilers
    class DslCompiler
      extend T::Sig

      sig { returns(T::Enumerable[Dsl::Base]) }
      attr_reader :generators
      sig { returns(T::Array[Module]) }
      attr_reader :requested_constants

      sig do
        params(
          requested_constants: T::Array[Module],
          requested_generators: T::Array[String]
        ).void
      end
      def initialize(requested_constants:, requested_generators: [])
        @generators = T.let(
          gather_generators(requested_generators),
          T::Enumerable[Dsl::Base]
        )
        @requested_constants = requested_constants
      end

      sig { params(blk: T.proc.params(constant: Module, rbi: String).void).void }
      def run(&blk)
        constants_to_process = gather_constants(requested_constants)

        if constants_to_process.empty?
          $stderr.puts "!!! No classes/modules can be matched for RBI generation."
          $stderr.puts "!!! Please check that the requested classes/modules include processable DSL methods."
          exit(1)
        end

        constants_to_process.each do |constant|
          rbi = rbi_for_constant(constant)
          next if rbi.nil?

          blk.call(constant, rbi)
        end
      end

      private

      sig { params(requested_generators: T::Array[String]).returns(Proc) }
      def generator_filter(requested_generators)
        return proc { true } if requested_generators.empty?

        generators = requested_generators.map(&:downcase)

        proc do |klass|
          generator = klass.name&.sub(/^Tapioca::Compilers::Dsl::/, '')&.downcase
          generators.include?(generator)
        end
      end

      sig { params(requested_generators: T::Array[String]).returns(T::Enumerable[Dsl::Base]) }
      def gather_generators(requested_generators)
        generator_filter = generator_filter(requested_generators)

        Dsl::Base.descendants.select(&generator_filter).map(&:new)
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
          $stderr.puts "=== Error ==="
          $stderr.puts msg
          $stderr.puts "# Candidates"
          candidates.each_with_index do |candidate, index|
            $stderr.puts "#{index}. #{candidate.describe}"
          end
          exit 1
        end
      end
    end
  end
end
