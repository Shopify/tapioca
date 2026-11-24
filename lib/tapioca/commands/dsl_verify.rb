# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class DslVerify < AbstractDsl
      private

      # @override
      #: -> void
      def execute
        load_application

        say("Checking for out-of-date RBIs...")
        say("")

        outpath = Pathname.new(Dir.mktmpdir)

        # Only RBIs that differ from the committed ones are written to `outpath`.
        generated_files = compile_dsl_rbi_files(outpath, quiet: true, unchanged_in: @outpath)
        say("")

        perform_dsl_verification(outpath, generated_files: generated_files)
      end
    end
  end
end
