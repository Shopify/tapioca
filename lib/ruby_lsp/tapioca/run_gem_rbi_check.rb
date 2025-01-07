# typed: true
# frozen_string_literal: true

require "ruby_lsp/tapioca/lockfile_diff_parser"

module RubyLsp
  module Tapioca
    class RunGemRbiCheck
      extend T::Sig

      class GemRbiCheckResult < T::Struct
        prop :stdout, String
        prop :stderr, String
        prop :status, T.nilable(Process::Status)
      end

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
          if git_repo?
            lockfile_changed? ? generate_gem_rbis : cleanup_orphaned_rbis
          else
            @result.stdout = "Not a git repository"
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
          @result.stdout, @result.stderr, @result.status = T.unsafe(Open3).capture3(
            { "BUNDLE_GEMFILE" => "Gemfile" },
            "bin/tapioca",
            "gem",
            "--lsp_addon",
            *added_or_modified_gems,
          )
        elsif removed_gems.any?
          FileUtils.rm_f(Dir.glob("sorbet/rbi/gems/{#{removed_gems.join(",")}}@*.rbi"))

          @result.stdout = "Removed RBIs for: #{removed_gems.join(", ")}"
        end
      end

      sig { void }
      def cleanup_orphaned_rbis
        untracked_files = %x(git ls-files --others --exclude-standard sorbet/rbi/gems/).lines.map(&:strip)
        deleted_files = %x(git ls-files --deleted sorbet/rbi/gems/).lines.map(&:strip)

        deleted_rbis = []
        restored_rbis = []

        untracked_files.each do |file|
          File.delete(file)
          deleted_rbis << file
        end

        deleted_files.each do |file|
          %x(git checkout -- #{file})
          restored_rbis << file
        end

        @result.stdout = "Deleted untracked RBIs: #{deleted_rbis.join(", ")}" unless deleted_rbis.empty?
        @result.stdout += "\n" unless deleted_rbis.empty? || restored_rbis.empty?
        @result.stdout += "Restored deleted RBIs: #{restored_rbis.join(", ")}" unless restored_rbis.empty?
      end
    end
  end
end
