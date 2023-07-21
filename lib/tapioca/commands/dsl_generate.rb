# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class DslGenerate < AbstractDsl
      sig { override.void }
      def execute
        Loaders::Dsl.load_application(
          tapioca_path: @tapioca_path,
          eager_load: @requested_constants.empty? && @requested_paths.empty?,
          app_root: @app_root,
          halt_upon_load_error: @halt_upon_load_error,
        )

        say("Compiling DSL RBI files...")
        say("")

        all_requested_constants = @requested_constants + constants_from_requested_paths

        rbi_files_to_purge = existing_rbi_filenames(all_requested_constants)

        pipeline = create_pipeline

        processed_files = pipeline.run do |constant, contents|
          constant_name = T.must(Tapioca::Runtime::Reflection.name_of(constant))

          if @verbose && !@quiet
            say_status(:processing, constant_name, :yellow)
          end

          compile_dsl_rbi(
            constant_name,
            contents,
            outpath: @outpath,
            quiet: @quiet && !@verbose,
          )
        end

        processed_files.each { |filename| rbi_files_to_purge.delete(T.must(filename)) }

        say("")

        purge_stale_dsl_rbi_files(rbi_files_to_purge)
        say("Done", :green)

        if @auto_strictness
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
      end
    end
  end
end
