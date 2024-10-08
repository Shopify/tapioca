# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class DslVerify < AbstractDsl
      private

      sig { override.void }
      def execute
        load_application

        logger.info("Checking for out-of-date RBIs...")
        logger.info("")

        outpath = Pathname.new(Dir.mktmpdir)

        generate_dsl_rbi_files(outpath, quiet: true)
        logger.info("")

        perform_dsl_verification(outpath)
      end
    end
  end
end
