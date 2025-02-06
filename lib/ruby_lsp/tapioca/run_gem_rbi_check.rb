# typed: true
# frozen_string_literal: true

require "open3"
require "ruby_lsp/tapioca/lockfile_diff_parser"

module RubyLsp
  module Tapioca
    class RunGemRbiCheck
      extend T::Sig

      attr_reader :stdout
      attr_reader :status

      sig { params(project_path: String).void }
      def initialize(project_path)
        @project_path = project_path
        @stdout = T.let("", String)
        @status = T.let(nil, T.nilable(Process::Status))
      end

      sig { void }
      def run
        return log_message("Not a git repository") unless git_repo?

        cleanup_orphaned_rbis

        if lockfile_changed?
          yield(gems_to_generate)
        end
      end

      private

      attr_reader :project_path

      sig { returns(T.nilable(T::Boolean)) }
      def git_repo?
        _, status = Open3.capture2e("git", "rev-parse", "--is-inside-work-tree", chdir: project_path)
        status.success?
      end

      sig { returns(T::Boolean) }
      def lockfile_changed?
        !lockfile_diff.empty?
      end

      sig { returns(Pathname) }
      def lockfile
        @lockfile ||= T.let(Pathname(project_path).join("Gemfile.lock"), T.nilable(Pathname))
      end

      sig { returns(String) }
      def lockfile_diff
        @lockfile_diff ||= T.let(read_lockfile_diff, T.nilable(String))
      end

      sig { returns(String) }
      def read_lockfile_diff
        return "" unless lockfile.exist?

        execute_in_project_path("git", "diff", lockfile.to_s).strip
      end

      sig { returns(T::Array[String]) }
      def gems_to_generate
        parser = Tapioca::LockfileDiffParser.new(@lockfile_diff)
        added_or_modified_gems = parser.added_or_modified_gems

        return [] if added_or_modified_gems.none?

        log_message("Identified lockfile changes, attempting to generate gem RBIs...")
        added_or_modified_gems
      end

      sig { void }
      def cleanup_orphaned_rbis
        untracked_files = git_ls_gem_rbis("--others", "--exclude-standard")
        deleted_files = git_ls_gem_rbis("--deleted")

        delete_files(untracked_files, "Deleted untracked RBIs")
        restore_files(deleted_files, "Restored deleted RBIs")
      end

      sig { params(flags: T.untyped).returns(T::Array[String]) }
      def git_ls_gem_rbis(*flags)
        flags = T.unsafe(["git", "ls-files", *flags, "sorbet/rbi/gems/"])

        execute_in_project_path(*flags)
          .lines
          .map(&:strip)
      end

      sig { params(files: T::Array[String], message: String).void }
      def delete_files(files, message)
        files_to_remove = files.map { |file| File.join(project_path, file) }
        FileUtils.rm(files_to_remove)
        log_message("#{message}: #{files.join(", ")}") unless files.empty?
      end

      sig { params(files: T::Array[String], message: String).void }
      def restore_files(files, message)
        execute_in_project_path("git", "checkout", "--pathspec-from-file=-", stdin: files.join("\n"))
        log_message("#{message}: #{files.join(", ")}") unless files.empty?
      end

      sig { params(message: String).void }
      def log_message(message)
        @stdout += "#{message}\n"
      end

      def execute_in_project_path(*parts, stdin: nil)
        options = { chdir: project_path }
        options[:stdin_data] = stdin if stdin
        stdout_and_stderr, _status = T.unsafe(Open3).capture2e(*parts, options)
        stdout_and_stderr
      end
    end
  end
end
