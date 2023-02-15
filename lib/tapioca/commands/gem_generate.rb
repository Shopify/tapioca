# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class GemGenerate < AbstractGem
      private

      sig { override.void }
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
      ensure
        GitAttributes.create_generated_attribute_file(@outpath)
      end
    end
  end
end
