# typed: strict
# frozen_string_literal: true

RubyLsp::Addon.depend_on_ruby_lsp!(">= 0.23.1", "< 0.24")

begin
  # The Tapioca add-on depends on the Rails add-on to add a runtime component to the runtime server. We can allow the
  # add-on to work outside of a Rails context in the future, but that may require Tapioca spawning its own runtime
  # server
  require "ruby_lsp/ruby_lsp_rails/runner_client"
rescue LoadError
  return
end

require "zlib"

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
        @file_checksums = T.let({}, T::Hash[String, String])
        @outgoing_queue = T.let(nil, T.nilable(Thread::Queue))
      end

      sig { override.params(global_state: RubyLsp::GlobalState, outgoing_queue: Thread::Queue).void }
      def activate(global_state, outgoing_queue)
        @global_state = global_state
        return unless @global_state.enabled_feature?(:tapiocaAddon)

        @index = @global_state.index
        @outgoing_queue = outgoing_queue
        Thread.new do
          # Get a handle to the Rails add-on's runtime client. The call to `rails_runner_client` will block this thread
          # until the server has finished booting, but it will not block the main LSP. This has to happen inside of a
          # thread
          addon = T.cast(::RubyLsp::Addon.get("Ruby LSP Rails", ">= 0.3.17", "< 0.4"), ::RubyLsp::Rails::Addon)
          @rails_runner_client = addon.rails_runner_client
          @outgoing_queue << Notification.window_log_message("Activating Tapioca add-on v#{version}")
          @rails_runner_client.register_server_addon(File.expand_path("server_addon.rb", __dir__))
          @rails_runner_client.delegate_notification(
            server_addon_name: "Tapioca",
            request_name: "load_compilers_and_extensions",
            workspace_path: @global_state.workspace_path,
          )
        rescue IncompatibleApiError
          # The requested version for the Rails add-on no longer matches. We need to upgrade and fix the breaking
          # changes
          @outgoing_queue << Notification.window_log_message(
            "IncompatibleApiError: Cannot activate Tapioca LSP add-on",
            type: Constant::MessageType::WARNING,
          )
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
        return unless T.must(@global_state).enabled_feature?(:tapiocaAddon)
        return unless @rails_runner_client # Client is not ready

        constants = changes.flat_map do |change|
          path = URI(change[:uri]).to_standardized_path
          next if path.end_with?("_test.rb", "_spec.rb")
          next unless file_updated?(change, path)

          entries = T.must(@index).entries_for(change[:uri])
          next unless entries

          entries.filter_map do |entry|
            entry.name if entry.class == RubyIndexer::Entry::Class || entry.class == RubyIndexer::Entry::Module
          end
        end.compact

        return if constants.empty?

        @rails_runner_client.trigger_reload
        @rails_runner_client.delegate_notification(
          server_addon_name: "Tapioca",
          request_name: "dsl",
          constants: constants,
        )
      end

      private

      sig { params(change: T::Hash[Symbol, T.untyped], path: String).returns(T::Boolean) }
      def file_updated?(change, path)
        case change[:type]
        when Constant::FileChangeType::CREATED
          @file_checksums[path] = Zlib.crc32(File.read(path)).to_s
          return true
        when Constant::FileChangeType::CHANGED
          current_checksum = Zlib.crc32(File.read(path)).to_s
          if @file_checksums[path] == current_checksum
            T.must(@outgoing_queue) << Notification.window_log_message(
              "File has not changed. Skipping #{path}",
              type: Constant::MessageType::INFO,
            )
          else
            @file_checksums[path] = current_checksum
            return true
          end
        when Constant::FileChangeType::DELETED
          @file_checksums.delete(path)
        else
          T.must(@outgoing_queue) << Notification.window_log_message(
            "Unexpected file change type: #{change[:type]}",
            type: Constant::MessageType::WARNING,
          )
        end

        false
      end
    end
  end
end
