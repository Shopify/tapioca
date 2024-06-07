# typed: true
# frozen_string_literal: true

require_relative "client"
require "benchmark"

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

      sig { override.params(global_state: ::RubyLsp::GlobalState, outgoing_queue: Thread::Queue).void }
      def activate(global_state, outgoing_queue)
        # Addon is being activated. Gems may have been updated
        $stderr.puts("Activating Tapioca LSP addon v#{VERSION}")
        @index = global_state.index
        @tapioca.sync_gems
      end

      sig { override.void }
      def deactivate
      end

      # Inefficiently triggers a DSL generation everytime a file changes
      sig { params(changes: T::Array[{ uri: String, type: Integer }]).void }
      def workspace_did_change_watched_files(changes)
        paths = changes.filter_map { |c| URI(c[:uri]).path }
        # TODO: Compare performance of retrieving from index to supplying paths to tapioca
        constants = T.let([], T::Array[T.untyped])
        time = Benchmark.measure do
          files_to_entries = @index.instance_variable_get("@files_to_entries")
          constants = paths.map do |path|
            entries = files_to_entries[path]
            entries.map do |entry|
              next unless RubyIndexer::Entry::Namespace === entry

              entry.name
            end
          end.flatten
        end
        $stderr.puts "Retrieving index took: #{time.real}"

        @tapioca.dsl_with_path(paths)
        @tapioca.dsl(constants) if constants.any?
      end

      sig { override.returns(String) }
      def name
        "Tapioca"
      end
    end
  end
end
