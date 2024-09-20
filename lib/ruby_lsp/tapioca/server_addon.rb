# frozen_string_literal: true

require "tapioca/internal"

module RubyLsp
  module Tapioca
    class ServerAddon < ::RubyLsp::Rails::ServerAddon
      def name
        "Tapioca"
      end

      def execute(request, params)
        case request
        when "dsl"
          dsl(params)
        end
      rescue => e
        File.write("tapioca_lsp.log", "#{Time.now} #{e.full_message}", mode: "a")
      end

      private

      def dsl(params)
        command = ::Tapioca::Commands::DslGenerate.new(
          requested_constants: params[:constants],
          tapioca_path: ::Tapioca::TAPIOCA_DIR,
          requested_paths: [],
          outpath: Pathname.new(::Tapioca::DEFAULT_DSL_DIR),
          file_header: true,
          exclude: [],
          only: [],
        )

        command.generate_without_booting
      end
    end
  end
end
