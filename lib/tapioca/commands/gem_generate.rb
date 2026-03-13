# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class GemGenerate < AbstractGem
      private

      # @override
      #: -> void
      def execute
        Loaders::Gem.load_application(
          bundle: @bundle,
          prerequire: @prerequire,
          postrequire: @postrequire,
          default_command: default_command(:require),
          halt_upon_load_error: @halt_upon_load_error,
        )

        gem_queue = gems_to_generate(@gem_names).reject { |gem| @exclude.include?(gem.name) }
        anything_done = [
          perform_removals,
          gem_queue.any?,
        ].any?

        # Pre-compute bootstrap symbols for all gems in the main process
        # to avoid spawning individual `srb` processes in each forked worker.
        all_bootstrap_symbols = precompute_bootstrap_symbols(gem_queue.map(&:name))

        # Pre-parse YARD docs in a parallel phase so that compilation workers
        # can load pre-saved databases instead of re-parsing all source files.
        if @include_doc
          preparse_yard_docs(gem_queue)
        end

        Executor.new(gem_queue, number_of_workers: @number_of_workers).run_in_parallel do |gem|
          shell.indent do
            compile_gem_rbi(gem, bootstrap_symbols: all_bootstrap_symbols[gem.name])
            puts
          end
        end

        if anything_done
          validate_rbi_files(
            command: default_command(:gem, @gem_names.join(" ")),
            gem_dir: @outpath.to_s,
            dsl_dir: @dsl_dir,
            auto_strictness: @auto_strictness,
            gems: @bundle.dependencies,
          )

          say("All operations performed in working directory.", [:green, :bold])
          say("Please review changes and commit them.", [:green, :bold])
        else
          say("No operations performed, all RBIs are up-to-date.", [:green, :bold])
        end
      ensure
        GitAttributes.create_generated_attribute_file(@outpath)
      end

      #: (Array[Gemfile::GemSpec] gems) -> void
      def preparse_yard_docs(gems)
        cache_dir = Gemfile::GemSpec::YARD_CACHE_DIR

        # If all gems have cached YARD databases, skip the pre-parse phase entirely.
        # Workers will load directly from the persistent cache via parse_yard_docs.
        gems_needing_parse = gems.reject do |gem|
          cache_path = File.join(cache_dir, gem.rbi_file_name)
          if File.directory?(cache_path)
            gem.yard_db_path = cache_path
            true
          else
            false
          end
        end

        return if gems_needing_parse.empty?

        yard_dir = Dir.mktmpdir("tapioca-yard-")

        # Only fork workers for gems that don't have a cached YARD database.
        db_paths = Executor.new(gems_needing_parse, number_of_workers: @number_of_workers).run_in_parallel do |gem|
          db_path = File.join(yard_dir, gem.rbi_file_name)
          gem.save_yard_docs(db_path)
          db_path
        end

        gems_needing_parse.each_with_index do |gem, i|
          gem.yard_db_path = db_paths[i]
        end
      end

      #: (Array[String] gem_names) -> Array[Gemfile::GemSpec]
      def gems_to_generate(gem_names)
        return @bundle.dependencies if gem_names.empty?

        (gem_names - @exclude).each_with_object([]) do |gem_name, gems|
          gem = @bundle.gem(gem_name)

          if gem.nil?
            next if @lsp_addon

            raise Tapioca::Error, set_color("Error: Cannot find gem '#{gem_name}'", :red)
          end

          gems.concat(gem_dependencies(gem)) if @include_dependencies
          gems << gem
        end
      end

      #: (Gemfile::GemSpec gem, ?Array[Gemfile::GemSpec] dependencies) -> Array[Gemfile::GemSpec]
      def gem_dependencies(gem, dependencies = [])
        direct_dependencies = gem.dependencies.filter_map { |dependency| @bundle.gem(dependency.name) }
        gems = dependencies | direct_dependencies

        if direct_dependencies.empty?
          gems
        else
          direct_dependencies.reduce(gems) { |result, gem| gem_dependencies(gem, result) }
        end
      end
    end
  end
end
