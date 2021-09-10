# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  class GeneratorSpec < Minitest::HooksSpec
    attr_reader :outdir
    attr_reader :repo_path

    before(:all) do
      @repo_path = (Pathname.new(__dir__) / "support" / "repo").expand_path
      Bundler.with_unbundled_env do
        IO.popen(["bundle", "install", "--quiet"], chdir: @repo_path).read
        IO.popen(["bundle", "exec", "tapioca", "init"], chdir: @repo_path).read
      end
    end

    around(:each) do |&blk|
      FileUtils.rm_rf(T.unsafe(self).repo_path / "sorbet") if Dir.exist?(T.unsafe(self).repo_path / "sorbet")
      FileUtils.rm(T.unsafe(self).repo_path / "Gemfile.lock") if File.exist?(T.unsafe(self).repo_path / "Gemfile.lock")
      Dir.mktmpdir do |outdir|
        @outdir = outdir
        super(&blk)
      end
      FileUtils.rm_rf(T.unsafe(self).repo_path / "sorbet") if Dir.exist?(T.unsafe(self).repo_path / "sorbet")
      FileUtils.rm(T.unsafe(self).repo_path / "Gemfile.lock") if File.exist?(T.unsafe(self).repo_path / "Gemfile.lock")
    end
  end
end
