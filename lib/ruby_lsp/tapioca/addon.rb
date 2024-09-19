# typed: true
# frozen_string_literal: true

require "ruby_lsp/addon"
begin
  require "ruby-lsp-rails"
rescue LoadError
  return
end

require "tapioca/internal"

# require "ruby_lsp/ruby_lsp_rails/server" # for ServerAddon

# TODO: Use async pattern in Rails addo

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
        addon = T.cast(::RubyLsp::Addon.get("Ruby LSP Rails"), ::RubyLsp::Rails::Addon)

        Thread.new do
          @rails_runner_client = T.let(addon.rails_runner_client, T.nilable(RubyLsp::Rails::RunnerClient))
          T.must(@rails_runner_client).register_server_addon(File.expand_path("server_addon.rb", __dir__))
        end
      rescue AddonNotFoundError
        $stderr.puts("Tapioca LSP: The LSP will not be available as the Ruby LSP Rails addon was not found")
      end

      sig { override.void }
      def deactivate
      end

      sig { override.returns(String) }
      def name
        "Tapioca"
      end

      sig { params(changes: T::Array[{ uri: String, type: Integer }]).void }
      def workspace_did_change_watched_files(changes)
        unless @rails_runner_client
          $stderr.puts "Tapioca LSP: Rails runner client not available yet, skipping request"
          return
        end

        constants = changes.filter_map do |change|
          path = change[:uri].gsub("file://", "")

          entries = T.must(@index).entries_for(path, RubyIndexer::Entry::Namespace)
          next unless entries

          entries.grep_v(RubyIndexer::Entry::SingletonClass).map(&:name)
        end.flatten

        return if constants.empty?

        $stderr.puts "Tapioca LSP: Making DSL request with constants #{constants}"

        @rails_runner_client.send_notification(
          "server_addon/delegate",
          request_name: "dsl",
          server_addon_name: "Tapioca",
          constants: constants,
        )
      end
    end
  end
end
