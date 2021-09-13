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
      FileUtils.rm_rf(@repo_path / "sorbet") if Dir.exist?(@repo_path / "sorbet")
      FileUtils.rm(@repo_path / "Gemfile.lock") if File.exist?(@repo_path / "Gemfile.lock")
      Dir.mktmpdir do |outdir|
        @outdir = outdir
        super(&blk)
      end
      FileUtils.rm_rf(@repo_path / "sorbet") if Dir.exist?(@repo_path / "sorbet")
      FileUtils.rm(@repo_path / "Gemfile.lock") if File.exist?(@repo_path / "Gemfile.lock")
    end

    DEFAULT_OUTDIR = T.let("sorbet/rbi/dsl", String)

    sig { returns(Pathname) }
    def outpath
      @outpath = T.let(@outpath, T.nilable(Pathname))
      @outpath ||= Pathname.new(DEFAULT_OUTDIR)
    end
  end
end
