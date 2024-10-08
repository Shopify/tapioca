# typed: strict
# frozen_string_literal: true

RubyLsp::Addon.depend_on_ruby_lsp!(">= 0.19.1", "< 0.20")

begin
  # The Tapioca add-on depends on the Rails add-on to add a runtime component to the runtime server. We can allow the
  # add-on to work outside of a Rails context in the future, but that may require Tapioca spawning its own runtime
  # server
  require "ruby-lsp-rails"
rescue LoadError
  return
end

module RubyLsp
  module Tapioca
    class Addon < ::RubyLsp::Addon
      extend T::Sig

      sig { void }
      def initialize
        super

        @global_state = T.let(nil, T.nilable(RubyLsp::GlobalState))
        @rails_runner_client = T.let(nil, T.nilable(RubyLsp::Rails::RunnerClient))
        @index = T.let(nil, T.nilable(RubyIndexer::Index))
      end

      sig { override.params(global_state: RubyLsp::GlobalState, outgoing_queue: Thread::Queue).void }
      def activate(global_state, outgoing_queue)
        @global_state = global_state
        # TODO: Uncomment
        # return unless @global_state.experimental_features

        @index = @global_state.index
        Thread.new do
          # Get a handle to the Rails add-on's runtime client. The call to `rails_runner_client` will block this thread
          # until the server has finished booting, but it will not block the main LSP. This has to happen inside of a
          # thread
          addon = T.cast(::RubyLsp::Addon.get("Ruby LSP Rails", ">= 0.3.18", "< 0.4"), ::RubyLsp::Rails::Addon)
          @rails_runner_client = addon.rails_runner_client
          @rails_runner_client.register_server_addon(File.expand_path("server_addon.rb", __dir__))
        rescue IncompatibleApiError
          # The requested version for the Rails add-on no longer matches. We need to upgrade and fix the breaking
          # changes
        end
      end

      sig { override.void }
      def deactivate
      end

      sig { override.returns(String) }
      def name
        "Tapioca"
      end

      sig { override.returns(String) }
      def version
        "0.1.0"
      end

      sig { params(changes: T::Array[{ uri: String, type: Integer }]).void }
      def workspace_did_change_watched_files(changes)
        return unless T.must(@global_state).experimental_features
        return unless @rails_runner_client # Client is not ready

        constants = changes.flat_map do |change|
          path = URI(change[:uri]).to_standardized_path
          entries = T.must(@index).entries_for(path)
          next unless entries

          entries.filter_map do |entry|
            entry.name if entry.class == RubyIndexer::Entry::Class || entry.class == RubyIndexer::Entry::Module
          end
        end

        return if constants.empty?

        @rails_runner_client.trigger_reload
        @rails_runner_client.delegate_notification(
          server_addon_name: "Tapioca",
          request_name: "dsl",
          constants: constants,
        )
      end
    end
  end
end
