# typed: strict
# frozen_string_literal: true

RubyLsp::Addon.depend_on_ruby_lsp!(">= 0.20", "< 0.22")

begin
  # The Tapioca add-on depends on the Rails add-on to add a runtime component to the runtime server. We can allow the
  # add-on to work outside of a Rails context in the future, but that may require Tapioca spawning its own runtime
  # server
  require "ruby-lsp-rails"
rescue LoadError
  return
end

require "zlib"

module RubyLsp
  module Tapioca
    class Addon < ::RubyLsp::Addon
      extend T::Sig

      GEMFILE_LOCK_SNAPSHOT = "tmp/tapioca/.gemfile_lock_snapshot"

      sig { void }
      def initialize
        super

        @global_state = T.let(nil, T.nilable(RubyLsp::GlobalState))
        @rails_runner_client = T.let(nil, T.nilable(RubyLsp::Rails::RunnerClient))
        @index = T.let(nil, T.nilable(RubyIndexer::Index))
        @file_checksums = T.let({}, T::Hash[String, String])
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
          outgoing_queue << Notification.window_log_message("Activating Tapioca add-on v#{version}")
          @rails_runner_client.register_server_addon(File.expand_path("server_addon.rb", __dir__))

          handle_gemfile_changes
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
        # TODO: Uncomment
        # return unless T.must(@global_state).experimental_features
        return unless @rails_runner_client # Client is not ready

        constants = changes.flat_map do |change|
          path = URI(change[:uri]).to_standardized_path
          next if path.end_with?("_test.rb", "_spec.rb")

          case change[:type]
          when Constant::FileChangeType::CREATED, Constant::FileChangeType::CHANGED
            content = File.read(path)
            current_checksum = Zlib.crc32(content).to_s

            if change[:type] == Constant::FileChangeType::CHANGED && @file_checksums[path] == current_checksum
              $stderr.puts "File has not changed. Skipping #{path}"
              next
            end

            @file_checksums[path] = current_checksum
          when Constant::FileChangeType::DELETED
            @file_checksums.delete(path)
          end

          entries = T.must(@index).entries_for(path)
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

      sig { void }
      def handle_gemfile_changes
        return unless File.exist?(".git")

        gemfile_status = %x(git status --porcelain Gemfile.lock).strip
        return if gemfile_status.empty?

        process_gemfile_changes
      end

      sig { returns(T.nilable(Integer)) }
      def process_gemfile_changes
        current_lockfile = File.read("Gemfile.lock")
        snapshot_lockfile = File.read(GEMFILE_LOCK_SNAPSHOT) if File.exist?(GEMFILE_LOCK_SNAPSHOT)

        unless snapshot_lockfile
          $stdout.puts("Creating initial Gemfile.lock snapshot at #{GEMFILE_LOCK_SNAPSHOT}")
          FileUtils.mkdir_p(File.dirname(GEMFILE_LOCK_SNAPSHOT))
          File.write(GEMFILE_LOCK_SNAPSHOT, current_lockfile)
          return
        end

        return if current_lockfile == snapshot_lockfile

        T.must(@rails_runner_client).delegate_notification(
          server_addon_name: "Tapioca",
          request_name: "gem",
          snapshot_lockfile: snapshot_lockfile,
          current_lockfile: current_lockfile,
        )

        File.write(GEMFILE_LOCK_SNAPSHOT, current_lockfile)
      end
    end
  end
end
