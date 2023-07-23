# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class DslVerify < AbstractDsl
      private

      sig { override.void }
      def execute
        Loaders::Dsl.load_application(
          tapioca_path: @tapioca_path,
          eager_load: @requested_constants.empty? && @requested_paths.empty?,
          app_root: @app_root,
          halt_upon_load_error: @halt_upon_load_error,
        )

        say("Checking for out-of-date RBIs...")
        say("")

        all_requested_constants = @requested_constants + constants_from_requested_paths

        outpath = Pathname.new(Dir.mktmpdir)
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
            outpath: outpath,
            quiet: true,
          )
        end

        processed_files.each { |filename| rbi_files_to_purge.delete(T.must(filename)) }

        say("")

        perform_dsl_verification(outpath)
      end
    end
  end
end
