# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class DslGenerate < AbstractDsl
      #: (?only_bootsnap_rbs_cache: bool, **untyped) -> void
      def initialize(only_bootsnap_rbs_cache: false, **kwargs)
        @only_bootsnap_rbs_cache = only_bootsnap_rbs_cache
        super(**T.unsafe(kwargs))
      end

      private

      # @override
      #: -> void
      def execute
        load_application

        if @only_bootsnap_rbs_cache
          if ENV["TAPIOCA_RBS_CACHE"] == "1"
            say("Bootsnap RBS cache populated, exiting before RBI generation.", :green)
          else
            say_error("Warning: --only-bootsnap-rbs-cache requires TAPIOCA_RBS_CACHE=1 to populate the cache", :yellow)
          end
          return
        end

        say("Compiling DSL RBI files...")
        say("")

        rbi_files_to_purge = generate_dsl_rbi_files(@outpath, quiet: @quiet && !@verbose)
        say("")

        purge_stale_dsl_rbi_files(rbi_files_to_purge) unless @lsp_addon
        say("Done", :green)

        if @auto_strictness && !@lsp_addon
          say("")
          validate_rbi_files(
            command: default_command(:dsl, all_requested_constants.join(" ")),
            gem_dir: @gem_dir,
            dsl_dir: @outpath.to_s,
            auto_strictness: @auto_strictness,
            compilers: pipeline.active_compilers,
          )
        end

        say("All operations performed in working directory.", [:green, :bold])
        say("Please review changes and commit them.", [:green, :bold])
      ensure
        GitAttributes.create_generated_attribute_file(@outpath)
      end
    end
  end
end
