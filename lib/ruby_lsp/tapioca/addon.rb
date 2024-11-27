# typed: strict
# frozen_string_literal: true

RubyLsp::Addon.depend_on_ruby_lsp!(">= 0.22.1", "< 0.23")

begin
  # The Tapioca add-on depends on the Rails add-on to add a runtime component to the runtime server. We can allow the
  # add-on to work outside of a Rails context in the future, but that may require Tapioca spawning its own runtime
  # server
  require "ruby_lsp/ruby_lsp_rails/runner_client"
rescue LoadError
  return
end

require "zlib"
require "open3"
require "ruby_lsp/tapioca/lockfile_diff_parser"

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
        @lockfile_diff = T.let(nil, T.nilable(String))
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

          if git_repo?
            lockfile_changed? ? generate_gem_rbis : cleanup_orphaned_rbis
          end
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

      sig { returns(T::Boolean) }
      def git_repo?
        Dir.exist?(".git")
      end

      sig { returns(T::Boolean) }
      def lockfile_changed?
        fetch_lockfile_diff
        !T.must(@lockfile_diff).empty?
      end

      sig { returns(String) }
      def fetch_lockfile_diff
        @lockfile_diff = %x(git diff HEAD Gemfile.lock).strip
      end

      sig { void }
      def generate_gem_rbis
        parser = LockfileDiffParser.new(@lockfile_diff)

        removed_gems = parser.removed_gems
        added_or_modified_gems = parser.added_or_modified_gems

        if added_or_modified_gems.any?
          # Resetting BUNDLE_GEMFILE to root folder to use the project's Gemfile instead of Ruby LSP's composed Gemfile
          stdout, stderr, status = T.unsafe(Open3).capture3(
            { "BUNDLE_GEMFILE" => "Gemfile" },
            "bin/tapioca",
            "gem",
            "--lsp_addon",
            *added_or_modified_gems,
          )
          T.must(@outgoing_queue) << if status.success?
            Notification.window_log_message(
              stdout,
              type: Constant::MessageType::INFO,
            )
          else
            Notification.window_log_message(
              stderr,
              type: Constant::MessageType::ERROR,
            )
          end
        elsif removed_gems.any?
          FileUtils.rm_f(Dir.glob("sorbet/rbi/gems/{#{removed_gems.join(",")}}@*.rbi"))
          T.must(@outgoing_queue) << Notification.window_log_message(
            "Removed RBIs for: #{removed_gems.join(", ")}",
            type: Constant::MessageType::INFO,
          )
        end
      end

      sig { void }
      def cleanup_orphaned_rbis
        untracked_files = %x(git ls-files --others --exclude-standard sorbet/rbi/gems/).lines.map(&:strip)
        deleted_files = %x(git ls-files --deleted sorbet/rbi/gems/).lines.map(&:strip)

        untracked_files.each do |file|
          File.delete(file)

          T.must(@outgoing_queue) << Notification.window_log_message(
            "Deleted untracked RBI: #{file}",
            type: Constant::MessageType::INFO,
          )
        end

        deleted_files.each do |file|
          %x(git checkout -- #{file})

          T.must(@outgoing_queue) << Notification.window_log_message(
            "Restored deleted RBI: #{file}",
            type: Constant::MessageType::INFO,
          )
        end
      end
    end
  end
end
