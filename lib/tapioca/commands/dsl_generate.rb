# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class DslGenerate < AbstractDsl
      private

      sig { override.void }
      def execute
        require "shopify/types/setup" # FIXME: total nasty hack

        ::TapiocaTracer.in_root_span(
          "DslGenerate.execute",
          attributes: {
            "service.name" => "Tapioca",
            "root.service.name" => "Tapioca",
          },
        ) do
          benchmark("DslGenerate.load_application") { load_application }

          say("Compiling DSL RBI files...")
          say("")

          rbi_files_to_purge = benchmark("generate_dsl_rbi_files") do
            generate_dsl_rbi_files(@outpath, quiet: @quiet && !@verbose)
          end
          say("")

          benchmark("purge_stale_dsl_rbi_files") { purge_stale_dsl_rbi_files(rbi_files_to_purge) }
          say("Done", :green)

          if @auto_strictness
            say("")
            benchmark("validate_rbi_files") do
              validate_rbi_files(
                command: default_command(:dsl, all_requested_constants.join(" ")),
                gem_dir: @gem_dir,
                dsl_dir: @outpath.to_s,
                auto_strictness: @auto_strictness,
                compilers: pipeline.active_compilers,
              )
            end
          end

          say("All operations performed in working directory.", [:green, :bold])
          say("Please review changes and commit them.", [:green, :bold])
        end
      ensure
        GitAttributes.create_generated_attribute_file(@outpath)
      end
    end
  end
end
