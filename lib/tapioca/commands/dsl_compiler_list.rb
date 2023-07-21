# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class DslCompilerList < AbstractDsl
      sig { override.void }
      def execute
        Loaders::Dsl.load_application(
          tapioca_path: @tapioca_path,
          eager_load: @requested_constants.empty? && @requested_paths.empty?,
          app_root: @app_root,
          halt_upon_load_error: @halt_upon_load_error,
        )

        pipeline = create_pipeline

        say("")
        say("Loaded DSL compiler classes:")
        say("")

        table = pipeline.compilers.map do |compiler|
          status = if pipeline.active_compilers.include?(compiler)
            set_color("enabled", :green)
          else
            set_color("disabled", :red)
          end

          [compiler.name, status]
        end

        print_table(table, { indent: 2 })
      end
    end
  end
end
