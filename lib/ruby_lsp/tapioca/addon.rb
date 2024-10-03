# typed: true
# frozen_string_literal: true

return unless defined?(RubyLsp)

require "ruby_lsp/internal"
require "tapioca/internal"

module RubyLsp
  module Tapioca
    class Addon < ::RubyLsp::Addon
      extend T::Sig

      def initialize
        super
        @index = T.let(nil, T.nilable(RubyIndexer::Index))
      end

      def rails_runner_stdin
        stdin = @global_state.instance_variable_get(:@rails_runner_stdin)
        @rails_runner_stdin ||= stdin
      end

      def activate(global_state, outgoing_queue)
        $stderr.puts("Activating Tapioca LSP addon v#{VERSION}")
        @index = global_state.index
        @global_state = global_state
      end

      sig { override.void }
      def deactivate
      end

      sig { override.returns(String) }
      def name
        "Tapioca"
      end

      def self.dsl(params)
        File.write("output.txt", "DSL called: #{params[:constants]}\n", mode: "a")
        # $stdout.reopen("tapioca.txt", "w")
        # $stderr.reopen("tapioca_err.txt", "w")
        # TODO: We reload the CLI so that thor defaults are set. ConfigHelper sets them to nil after starting
        load("tapioca/cli.rb")
        ::Tapioca::Cli.start(["dsl", "--lsp_addon"] + params[:constants])
      end

      sig { params(changes: T::Array[{ uri: String, type: Integer }]).void }
      def workspace_did_change_watched_files(changes)
        files_to_entries = @index.instance_variable_get("@files_to_entries")
        constants = changes.map do |change|
          path = change[:uri].gsub("file://", "")
          entries = files_to_entries[path]
          next unless entries

          entries.map do |entry|
            next unless entry.class == RubyIndexer::Entry::Class ||
              entry.class == RubyIndexer::Entry::Module

            entry.name
          end
        end.flatten.compact

        if constants.any?
          send_message("reload", {})
          send_message("tapioca_dsl", constants: constants)
        end
      end

      sig { params(request: String, params: T::Hash[Symbol, T.untyped]).void }
      def send_message(request, params)
        message = { method: request, params: params }
        json = message.to_json

        $stderr.puts "Tapioca LSP: Sending message with #{params}: #{json}"
        stdin = rails_runner_stdin
        stdin.write("Content-Length: #{json.length}\r\n\r\n", json)
      end
    end
  end
end
