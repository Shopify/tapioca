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
      end

      sig { override.params(global_state: GlobalState, outgoing_queue: Thread::Queue).void }
      def activate(global_state, outgoing_queue)
        # Addon is being activated. Gems may have been updated
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
        @tapioca.dsl(paths)
      end

      sig { override.returns(String) }
      def name
        "Tapioca"
      end
    end
  end
end
