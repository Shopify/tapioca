# typed: strict
# frozen_string_literal: true

require "open3"
require "ruby_lsp/tapioca/lockfile_diff_parser"

module RubyLsp
  module Tapioca
    class RunGemRbiCheck
      #: String
      attr_reader :stdout, :stderr

      #: Process::Status?
      attr_reader :status

      #: (String project_path) -> void
      def initialize(project_path)
        @project_path = project_path
        @stdout = "" #: String
        @stderr = "" #: String
        @status = nil #: Process::Status?
      end

      #: -> void
      def run
        return log_message("Not a git repository") unless git_repo?

        cleanup_orphaned_rbis

        if lockfile_changed?
          generate_gem_rbis
        end
      end

      private

      #: -> bool?
      def git_repo?
        _, status = Open3.capture2e("git", "rev-parse", "--is-inside-work-tree", chdir: @project_path)
        status.success?
      end

      #: -> bool
      def lockfile_changed?
        !lockfile_diff.empty?
      end

      #: -> Pathname
      def lockfile
        @lockfile ||= Pathname(@project_path).join("Gemfile.lock") #: Pathname?
      end

      #: -> String
      def lockfile_diff
        @lockfile_diff ||= read_lockfile_diff #: String?
      end

      #: -> String
      def read_lockfile_diff
        return "" unless lockfile.exist?

        execute_in_project_path("git", "diff", lockfile.to_s).strip
      end

      #: -> void
      def generate_gem_rbis
        parser = Tapioca::LockfileDiffParser.new(@lockfile_diff)
        removed_gems = parser.removed_gems
        added_or_modified_gems = parser.added_or_modified_gems

        if added_or_modified_gems.any?
          log_message("Identified lockfile changes, attempting to generate gem RBIs...")
          execute_tapioca_gem_command(added_or_modified_gems)
        elsif removed_gems.any?
          remove_rbis(removed_gems)
        end
      end

      #: (Array[String] gems) -> void
      def execute_tapioca_gem_command(gems)
        Bundler.with_unbundled_env do
          stdout, stderr, status = Open3 #: as untyped
            .capture3(
              "bundle",
              "exec",
              "tapioca",
              "gem",
              "--lsp_addon",
              *gems,
              chdir: @project_path,
            )

          log_message(stdout) unless stdout.empty?
          @stderr = stderr unless stderr.empty?
          @status = status
        end
      end

      #: (Array[String] gems) -> void
      def remove_rbis(gems)
        files = Dir.glob(
          "sorbet/rbi/gems/{#{gems.join(",")}}@*.rbi",
          base: @project_path,
        )
        delete_files(files, "Removed RBIs for")
      end

      #: -> void
      def cleanup_orphaned_rbis
        untracked_files = git_ls_gem_rbis("--others", "--exclude-standard")
        deleted_files = git_ls_gem_rbis("--deleted")

        delete_files(untracked_files, "Deleted untracked RBIs")
        restore_files(deleted_files, "Restored deleted RBIs")
      end

      #: (*untyped flags) -> Array[String]
      def git_ls_gem_rbis(*flags)
        self #: as untyped # rubocop:disable Style/RedundantSelf
          .execute_in_project_path("git", "ls-files", *flags, "sorbet/rbi/gems/")
          .lines
          .map(&:strip)
      end

      #: (Array[String] files, String message) -> void
      def delete_files(files, message)
        files_to_remove = files.map { |file| File.join(@project_path, file) }
        FileUtils.rm(files_to_remove)
        log_message("#{message}: #{files.join(", ")}") unless files.empty?
      end

      #: (Array[String] files, String message) -> void
      def restore_files(files, message)
        execute_in_project_path("git", "checkout", "--pathspec-from-file=-", stdin: files.join("\n"))
        log_message("#{message}: #{files.join(", ")}") unless files.empty?
      end

      #: (String message) -> void
      def log_message(message)
        @stdout += "#{message}\n"
      end

      #: (*String, ?stdin: String?) -> String
      def execute_in_project_path(*parts, stdin: nil)
        options = { chdir: @project_path }
        options[:stdin_data] = stdin if stdin
        stdout_and_stderr, _status = Open3 #: as untyped
          .capture2e(*parts, options)
        stdout_and_stderr
      end
    end
  end
end
