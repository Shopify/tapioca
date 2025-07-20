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
        anything_excluded = @skipped_gems

        Executor.new(gem_queue, number_of_workers: @number_of_workers).run_in_parallel do |gem|
          shell.indent do
            compile_gem_rbi(gem)
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
        unless anything_excluded.empty?
          say("\nNote, the following gems have been excluded from Tapioca:",[:yellow, :bold])
          say(@skipped_gems.join(", "), [:yellow, :bold])
        end
      ensure
        GitAttributes.create_generated_attribute_file(@outpath)
      end

      #: (Array[String] gem_names) -> Array[Gemfile::GemSpec]
      def gems_to_generate(gem_names)
        return @bundle.dependencies if gem_names.empty?

        (gem_names - @exclude).each_with_object([]) do |gem_name, gems|
          gem = @bundle.gem(gem_name)

          if gem.nil?
            if @lsp_addon
              next
            elsif Gemfile::GemSpec::IGNORED_GEMS.include?(gem_name)
              @skipped_gems << gem_name
              next
            else
              raise Tapioca::Error, set_color("Error: Cannot find gem '#{gem_name}'", :red)
            end
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
