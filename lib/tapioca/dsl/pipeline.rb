# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    class Pipeline
      extend T::Sig

      #: T::Enumerable[singleton(Compiler)]
      attr_reader :active_compilers

      #: Array[Module]
      attr_reader :requested_constants

      #: Array[Pathname]
      attr_reader :requested_paths

      #: Array[Module]
      attr_reader :skipped_constants

      #: ^(String error) -> void
      attr_reader :error_handler

      #: Array[String]
      attr_reader :errors

      #: (requested_constants: Array[Module], ?requested_paths: Array[Pathname], ?requested_compilers: Array[singleton(Compiler)], ?excluded_compilers: Array[singleton(Compiler)], ?error_handler: ^(String error) -> void, ?skipped_constants: Array[Module], ?number_of_workers: Integer?, ?compiler_options: Hash[String, untyped], ?lsp_addon: bool) -> void
      def initialize(
        requested_constants:,
        requested_paths: [],
        requested_compilers: [],
        excluded_compilers: [],
        error_handler: $stderr.method(:puts).to_proc,
        skipped_constants: [],
        number_of_workers: nil,
        compiler_options: {},
        lsp_addon: false
      )
        @active_compilers =
          gather_active_compilers(requested_compilers, excluded_compilers) #: Enumerable[singleton(Compiler)]
        @requested_constants = requested_constants
        @requested_paths = requested_paths
        @error_handler = error_handler
        @skipped_constants = skipped_constants
        @number_of_workers = number_of_workers
        @compiler_options = compiler_options
        @lsp_addon = lsp_addon
        @errors = [] #: Array[String]
      end

      #: [T] { (Module constant, RBI::File rbi) -> T } -> Array[T]
      def run(&blk)
        constants_to_process = gather_constants(requested_constants, requested_paths, skipped_constants)
          .select { |c| Module === c } # Filter value constants out
          .sort_by! { |c| T.must(Runtime::Reflection.name_of(c)) }

        # It's OK if there are no constants to process if we received a valid file/path.
        if constants_to_process.empty? && requested_paths.none? { |p| File.exist?(p) }
          report_error(<<~ERROR)
            No classes/modules can be matched for RBI generation.
            Please check that the requested classes/modules include processable DSL methods.
          ERROR
          raise Tapioca::Error, ""
        end

        if defined?(::ActiveRecord::Base) && constants_to_process.any? { |c| ::ActiveRecord::Base > c }
          abort_if_pending_migrations!
        end

        result = Executor.new(
          constants_to_process,
          number_of_workers: @number_of_workers,
        ).run_in_parallel do |constant|
          rbi = rbi_for_constant(constant)
          next if rbi.nil?

          blk.call(constant, rbi)
        end

        if errors.any?
          errors.each do |msg|
            report_error(msg)
          end

          raise Tapioca::Error, ""
        end

        result.compact
      end

      #: (String error) -> void
      def add_error(error)
        @errors << error
      end

      #: (String compiler_name) -> bool
      def compiler_enabled?(compiler_name)
        potential_names = Compilers::NAMESPACES.map { |namespace| namespace + compiler_name }

        active_compilers.any? do |compiler|
          potential_names.any?(compiler.name)
        end
      end

      #: -> Array[singleton(Compiler)]
      def compilers
        @compilers ||= Runtime::Reflection.descendants_of(Compiler).sort_by do |compiler|
          T.must(compiler.name)
        end #: Array[singleton(Compiler)]?
      end

      private

      #: (Array[singleton(Compiler)] requested_compilers, Array[singleton(Compiler)] excluded_compilers) -> T::Enumerable[singleton(Compiler)]
      def gather_active_compilers(requested_compilers, excluded_compilers)
        active_compilers = compilers
        active_compilers -= excluded_compilers
        active_compilers &= requested_compilers unless requested_compilers.empty?
        active_compilers
      end

      #: (Array[Module] requested_constants, Array[Pathname] requested_paths, Array[Module] skipped_constants) -> Set[Module]
      def gather_constants(requested_constants, requested_paths, skipped_constants)
        Compiler.requested_constants = requested_constants
        constants = Set.new.compare_by_identity
        active_compilers.each do |compiler|
          constants.merge(compiler.processable_constants)
        end
        constants = filter_anonymous_and_reloaded_constants(constants)
        constants -= skipped_constants

        unless requested_constants.empty? && requested_paths.empty?
          constants &= requested_constants

          requested_and_skipped = requested_constants & skipped_constants
          if requested_and_skipped.any?
            $stderr.puts("WARNING: Requested constants are being skipped due to configuration:" \
              "#{requested_and_skipped}. Check the supplied arguments and your `sorbet/tapioca/config.yml` file.")
          end
        end
        constants
      end

      #: (Set[Module] constants) -> Set[Module]
      def filter_anonymous_and_reloaded_constants(constants)
        # Group constants by their names
        constants_by_name = constants
          .group_by { |c| Runtime::Reflection.name_of(c) }
          .select { |name, _| !name.nil? }

        constants_by_name = T.cast(constants_by_name, T::Hash[String, T::Array[Module]])

        # Find the constants that have been reloaded
        reloaded_constants = constants_by_name.select { |_, constants| constants.size > 1 }.keys

        unless reloaded_constants.empty? || @lsp_addon
          reloaded_constant_names = reloaded_constants.map { |name| "`#{name}`" }.join(", ")

          $stderr.puts("WARNING: Multiple constants with the same name: #{reloaded_constant_names}")
          $stderr.puts("Make sure some object is not holding onto these constants during an app reload.")
        end

        # Look up all the constants back from their names. The resulting constant set will be the
        # set of constants that are actually in memory with those names.
        filtered_constants = constants_by_name
          .keys
          .map { |name| T.cast(Runtime::Reflection.constantize(name), Module) }
          .select { |mod| Runtime::Reflection.constant_defined?(mod) }

        Set.new.compare_by_identity.merge(filtered_constants)
      end

      #: (Module constant) -> RBI::File?
      def rbi_for_constant(constant)
        file = RBI::File.new(strictness: "true")

        active_compilers.each do |compiler_class|
          next unless compiler_class.handles?(constant)

          compiler = compiler_class.new(self, file.root, constant, @compiler_options)
          compiler.decorate
        rescue
          $stderr.puts("Error: `#{compiler_class.name}` failed to generate RBI for `#{constant}`")
          raise # This is an unexpected error, so re-raise it
        end

        return if file.root.empty?

        file
      end

      #: (String error) -> void
      def report_error(error)
        handler = error_handler
        handler.call(error)
      end

      #: -> void
      def abort_if_pending_migrations!
        # When running within the add-on, we cannot invoke the abort if pending migrations task because that will exit
        # the process and crash the Rails runtime server. Instead, the Rails add-on checks for pending migrations and
        # warns the user, so that they are aware they need to migrate their database
        return if @lsp_addon
        return unless defined?(::Rake)

        Rails.application.load_tasks

        if Rake::Task.task_defined?("db:abort_if_pending_migrations")
          Rake::Task["db:abort_if_pending_migrations"].invoke
        end
      end
    end
  end
end
