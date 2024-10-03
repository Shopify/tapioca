# typed: strict
# frozen_string_literal: true

RubyLsp::Addon.depend_on_ruby_lsp!(">= 0.19", "< 0.20")

begin
  # The Tapioca add-on depends on the Rails add-on to add a runtime component to the runtime server. We can allow the
  # add-on to work outside of a Rails context in the future, but that may require Tapioca spawning its own runtime
  # server
  require "ruby-lsp-rails"
rescue LoadError
  return
end

require "tapioca/internal"

module RubyLsp
  module Tapioca
    class Addon < ::RubyLsp::Addon
      extend T::Sig

      sig { void }
      def initialize
        super

        @global_state = T.let(nil, T.nilable(RubyLsp::GlobalState))
        @rails_runner_client = T.let(nil, T.nilable(RubyLsp::Rails::RunnerClient))
      end

      sig { override.params(global_state: RubyLsp::GlobalState, outgoing_queue: Thread::Queue).void }
      def activate(global_state, outgoing_queue)
        @global_state = global_state
        return unless @global_state.experimental_features

        Thread.new do
          # Get a handle to the Rails add-on's runtime client. The call to `rails_runner_client` will block this thread
          # until the server has finished booting, but it will not block the main LSP. This has to happen inside of a
          # thread
          addon = T.cast(::RubyLsp::Addon.get("Ruby LSP Rails", ">= 0.3.17", "< 0.4"), ::RubyLsp::Rails::Addon)
          @rails_runner_client = addon.rails_runner_client
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
      end
    end
  end
end
