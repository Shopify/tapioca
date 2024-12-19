# typed: true

require "ruby_lsp/tapioca/lockfile_diff_parser"
require "ruby_lsp/tapioca/run_gem_rbi_check"

module RubyLsp
  module Tapioca
    # TODO: this could probably have a better name
    class RunGemRbiCheck
      extend T::Sig

      def initialize
        # We considered using logs to assert against things that other wise would be tricky to test directly,
        # but it may not be needed.
        @logs = []
      end

      attr_reader :logs

      def run(project_path = ".")
        FileUtils.chdir(project_path) do
          if git_repo?
            lockfile_changed? ? generate_gem_rbis : cleanup_orphaned_rbis
          else
            @logs << "Not a git repository"
          end
        end
      end

      private

      sig { returns(T::Boolean) }
      def git_repo?
        require "open3"

        _, status = Open3.capture2e("git rev-parse --is-inside-work-tree")

        T.must(status.success?)
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
        parser = Tapioca::LockfileDiffParser.new(@lockfile_diff)

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
          @logs << stdout
          @logs << stderr
          # T.must(@outgoing_queue) << if status.success?
          #   Notification.window_log_message(
          #     stdout,
          #     type: Constant::MessageType::INFO,
          #   )
          # else
          #   Notification.window_log_message(
          #     stderr,
          #     type: Constant::MessageType::ERROR,
          #   )
          # end
        elsif removed_gems.any?
          FileUtils.rm_f(Dir.glob("sorbet/rbi/gems/{#{removed_gems.join(",")}}@*.rbi"))
          # T.must(@outgoing_queue) << RubyLsp::Notification.window_log_message(
          #   "Removed RBIs for: #{removed_gems.join(", ")}",
          #   type: LanguageServer::Protocol::Constant::MessageType::INFO,
          # )
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

          T.must(@outgoing_queue) << RubyLsp::Notification.window_log_message(
            "Restored deleted RBI: #{file}",
            type: Constant::MessageType::INFO,
          )
        end
      end
    end
  end
end
