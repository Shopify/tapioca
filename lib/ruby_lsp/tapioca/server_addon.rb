# frozen_string_literal: true

require "tapioca/internal"
# require "ruby_lsp/ruby_lsp_rails/server" # for ServerAddon

module RubyLsp
  module Tapioca
    class ServerAddon < ::RubyLsp::Rails::ServerAddon
      def name
        "Tapioca"
      end

      def execute(request, params)
        $stderr.puts("Tapioca DSL execute")
        case request
        when "tapioca.dsl" # TODO: remove tapioca. prefix
          dsl(params)
        end
      end

      private

      def dsl(params)
        $stderr.puts("dsl...")
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
