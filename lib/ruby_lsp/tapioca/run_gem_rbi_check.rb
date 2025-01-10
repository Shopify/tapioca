# typed: true
# frozen_string_literal: true

require "ruby_lsp/tapioca/lockfile_diff_parser"

module RubyLsp
  module Tapioca
    class GemRbiCheckResult < T::Struct
      prop :stdout, String
      prop :stderr, String
      prop :status, T.nilable(Process::Status)
    end

    class RunGemRbiCheck
      extend T::Sig

      sig { void }
      def initialize
        @result = T.let(
          GemRbiCheckResult.new(stdout: "", stderr: "", status: nil),
          GemRbiCheckResult,
        )
      end

      attr_reader :result

      sig { params(project_path: String).returns(GemRbiCheckResult) }
      def run(project_path = ".")
        FileUtils.chdir(project_path) do
          $stderr.puts "Inside Run Method"
          if git_repo?
            $stderr.puts "Inside git_repo? Check"
            lockfile_changed? ? generate_gem_rbis : cleanup_orphaned_rbis
          else
            log_message("Not a git repository")
          end
        end

        @result
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
        $stdout.puts "Inside lockfile_changed? Method"
        fetch_lockfile_diff
        $stdout.puts "fetch_lockfile_diff = #{fetch_lockfile_diff}"
        !@lockfile_diff.empty?
      end

      sig { returns(String) }
      def fetch_lockfile_diff
        @lockfile_diff = File.exist?("Gemfile.lock") ? %x(git diff Gemfile.lock).strip : ""
      end

      sig { void }
      def generate_gem_rbis
        $stdout.puts "Inside generate_gem_rbis Method"
        parser = Tapioca::LockfileDiffParser.new(@lockfile_diff)
        removed_gems = parser.removed_gems
        added_or_modified_gems = parser.added_or_modified_gems

        if added_or_modified_gems.any?
          $stdout.puts "Inside if added_or_modified_gems.any? Check"
          log_message("Identified lockfile changes, attempting to generate gem RBIs...")
          execute_tapioca_gem_command(added_or_modified_gems)
        elsif removed_gems.any?
          $stdout.puts "Inside elsif removed_gems.any? Check"
          remove_rbis(removed_gems)
        end
      end

      sig { params(gems: T::Array[String]).void }
      def execute_tapioca_gem_command(gems)
        # Resetting BUNDLE_GEMFILE to root folder to use the project's Gemfile instead of Ruby LSP's composed Gemfile
        stdout, stderr, status = T.unsafe(Open3).capture3(
          { "BUNDLE_GEMFILE" => "Gemfile" },
          "bundle",
          "exec",
          "tapioca",
          "gem",
          "--lsp_addon",
          *gems,
        )

        log_message(stdout) unless stdout.empty?
        log_message(stderr) unless stderr.empty?
        @result.status = status
      end

      sig { params(gems: T::Array[String]).void }
      def remove_rbis(gems)
        FileUtils.rm_f(Dir.glob("sorbet/rbi/gems/{#{gems.join(",")}}@*.rbi"))
        log_message("Removed RBIs for: #{gems.join(", ")}")
      end

      sig { void }
      def cleanup_orphaned_rbis
        $stdout.puts "Inside cleanup_orphaned_rbis Method"
        untracked_files = %x(git ls-files --others --exclude-standard sorbet/rbi/gems/).lines.map(&:strip)
        deleted_files = %x(git ls-files --deleted sorbet/rbi/gems/).lines.map(&:strip)
        $stdout.puts "untracked_files = #{untracked_files}"
        $stdout.puts "deleted_files = #{deleted_files}"

        delete_files(untracked_files, "Deleted untracked RBIs")
        restore_files(deleted_files, "Restored deleted RBIs")
      end

      sig { params(files: T::Array[String], message: String).void }
      def delete_files(files, message)
        $stdout.puts "Inside delete_files Method"
        files.each { |file| File.delete(file) }
        log_message("#{message}: #{files.join(", ")}") unless files.empty?
      end

      sig { params(files: T::Array[String], message: String).void }
      def restore_files(files, message)
        $stdout.puts "Inside restore_files Method"
        files.each { |file| %x(git checkout -- #{file}) }
        log_message("#{message}: #{files.join(", ")}") unless files.empty?
      end

      sig { params(message: String).void }
      def log_message(message)
        $stderr.puts message
        @result.stdout += "#{message}\n"
      end
    end
  end
end
