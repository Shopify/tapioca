# typed: true
# frozen_string_literal: true

begin
  require "ruby-lsp-rails"
rescue LoadError
  return
end

require "tapioca/internal"

# bug? saving file before rails boots causes crash

module RubyLsp
  module Tapioca
    class Addon < ::RubyLsp::Addon
      extend T::Sig

      def initialize
        super
        @index = T.let(nil, T.nilable(RubyIndexer::Index))
      end

      def activate(global_state, outgoing_queue)
        $stderr.puts("Activating Tapioca LSP addon v#{VERSION}")
        @index = global_state.index
        @global_state = global_state
        @rails_addon = RubyLsp::Addon.get("Ruby LSP Rails")
      end

      sig { override.void }
      def deactivate
      end

      sig { override.returns(String) }
      def name
        "Tapioca"
      end

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

      sig { params(changes: T::Array[{ uri: String, type: Integer }]).void }
      def workspace_did_change_watched_files(changes)
        constants = changes.map do |change|
          path = change[:uri].gsub("file://", "")

          entries = @index.entries_for(path, RubyIndexer::Entry::Namespace)

          entries.map(&:name)
        end.flatten.compact

        # TODO: `tapioca/dsl` instead?
        $stderr.puts "Tapioca LSP: Making DSL request with constants #{constants}"
        @rails_addon.rails_runner_client.make_request("tapioca.dsl", constants: constants) if constants.any?
      end
    end
  end
end
