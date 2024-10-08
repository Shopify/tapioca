# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class DslGenerate < AbstractDsl
      private

      sig { override.void }
      def execute
        load_application

        logger.info("Compiling DSL RBI files...")
        logger.info("")

        rbi_files_to_purge = generate_dsl_rbi_files(@outpath, quiet: @quiet && !@verbose)
        logger.info("")

        purge_stale_dsl_rbi_files(rbi_files_to_purge)
        logger.info("Done", :green)

        if @auto_strictness
          logger.info("")
          validate_rbi_files(
            command: default_command(:dsl, all_requested_constants.join(" ")),
            gem_dir: @gem_dir,
            dsl_dir: @outpath.to_s,
            auto_strictness: @auto_strictness,
            compilers: pipeline.active_compilers,
          )
        end

        logger.info("All operations performed in working directory.", [:green, :bold])
        logger.info("Please review changes and commit them.", [:green, :bold])
      ensure
        GitAttributes.create_generated_attribute_file(@outpath)
      end
    end
  end
end
