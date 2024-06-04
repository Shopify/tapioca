# typed: strict
# frozen_string_literal: true

require_relative "client"

module RubyLsp
  module Tapioca
    class Addon < ::RubyLsp::Addon
      extend T::Sig

      sig { void }
      def initialize
        super
        @tapioca = T.let(Client.new, Client)
        @index = T.let(nil, T.nilable(RubyIndexer::Index))
      end

      sig { override.params(global_state: GlobalState, outgoing_queue: Thread::Queue).void }
      def activate(global_state, outgoing_queue)
        # Addon is being activated. Gems may have been updated
        @index = global_state.index
        $stderr.puts("Activating Tapioca LSP addon v#{VERSION}")
        @tapioca.sync_gems
      end

      sig { override.void }
      def deactivate
      end

      # Inefficiently triggers a DSL generation everytime a file changes
      sig { params(changes: T::Array[{ uri: String, type: Integer }]).void }
      def workspace_did_change_watched_files(changes)
        paths = changes.filter_map { |c| URI(c[:uri]).path }
        files_to_entries = @index.instance_variable_get("@files_to_entries")
        constants = paths.map do |path|
          entries = files_to_entries[path]
          entries.map do |entry|
            next unless RubyIndexer::Entry::Namespace === entry

            entry.name
          end
        end.flatten

        @tapioca.dsl(constants) if constants.any?
      end

      sig { override.returns(String) }
      def name
        "Tapioca"
      end
    end
  end
end
