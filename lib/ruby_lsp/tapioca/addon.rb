# typed: true
# frozen_string_literal: true

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
        File.write("output.txt", "#{Time.now} DSL called: #{params[:constants]}\n", mode: "a")
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
        files_to_entries = @index.instance_variable_get("@files_to_entries")
        constants = changes.map do |change|
          path = change[:uri].gsub("file://", "")
          entries = files_to_entries[path]
          return unless entries

          entries.map do |entry|
            next unless entry.class == RubyIndexer::Entry::Class ||
              entry.class == RubyIndexer::Entry::Module

            entry.name
          end
        end.flatten.compact

        send_message("tapioca_dsl", constants: constants) if constants.any?
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
