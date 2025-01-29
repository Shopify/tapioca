# typed: true
# frozen_string_literal: true

require "open3"
require "ruby_lsp/tapioca/lockfile_diff_parser"

module RubyLsp
  module Tapioca
    class RunGemRbiCheck
      extend T::Sig

      attr_reader :stdout
      attr_reader :stderr
      attr_reader :status

      sig { params(project_path: String).void }
      def initialize(project_path)
        @project_path = project_path
        @stdout = T.let("", String)
        @stderr = T.let("", String)
        @status = T.let(nil, T.nilable(Process::Status))
      end

      sig { void }
      def run
        return log_message("Not a git repository") unless git_repo?

        lockfile_changed? ? generate_gem_rbis : cleanup_orphaned_rbis
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

      sig { void }
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

      sig { params(gems: T::Array[String]).void }
      def execute_tapioca_gem_command(gems)
        Bundler.with_unbundled_env do
          stdout, stderr, status = T.unsafe(Open3).capture3(
            "bundle",
            "exec",
            "tapioca",
            "gem",
            "--lsp_addon",
            *gems,
            chdir: project_path,
          )

          log_message(stdout) unless stdout.empty?
          @stderr = stderr unless stderr.empty?
          @status = status
        end
      end

      sig { params(gems: T::Array[String]).void }
      def remove_rbis(gems)
        FileUtils.rm_f(Dir.glob("sorbet/rbi/gems/{#{gems.join(",")}}@*.rbi", base: project_path))
        log_message("Removed RBIs for: #{gems.join(", ")}")
      end

      sig { void }
      def cleanup_orphaned_rbis
        untracked_files = execute_in_project_path(
          "git",
          "ls-files",
          "--others",
          "--exclude-standard",
          "sorbet/rbi/gems/",
        ).lines.map(&:strip)
        deleted_files = execute_in_project_path("git", "ls-files", "--deleted", "sorbet/rbi/gems/").lines.map(&:strip)

        delete_files(untracked_files, "Deleted untracked RBIs")
        restore_files(deleted_files, "Restored deleted RBIs")
      end

      sig { params(files: T::Array[String], message: String).void }
      def delete_files(files, message)
        FileUtils.rm(files.map { |file| File.join(project_path, file) })
        log_message("#{message}: #{files.join(", ")}") unless files.empty?
      end

      sig { params(files: T::Array[String], message: String).void }
      def restore_files(files, message)
        files.each { |file| execute_in_project_path("git", "checkout", "--", file) }
        log_message("#{message}: #{files.join(", ")}") unless files.empty?
      end

      sig { params(message: String).void }
      def log_message(message)
        @stdout += "#{message}\n"
      end

      def execute_in_project_path(*parts)
        stdout_and_stderr, _status = T.unsafe(Open3).capture2e(*parts, chdir: project_path)
        stdout_and_stderr
      end
    end
  end
end
