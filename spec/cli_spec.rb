# typed: true
# frozen_string_literal: true

require "spec_helper"
require "pathname"
require "shellwords"

module Tapioca
  class CliSpec < Minitest::HooksSpec
    extend T::Sig

    attr_reader :outdir
    attr_reader :repo_path

    sig { params(command: String, use_default_outdir: T::Boolean, number_of_workers: Integer).returns(String) }
    def tapioca(command, use_default_outdir: false, number_of_workers: 1)
      exec_command = [
        "bundle",
        "exec",
        "tapioca",
        command,
      ]

      exec_command << "--outdir #{outdir}" unless use_default_outdir
      exec_command << "--workers=#{number_of_workers}" if command.start_with?("gem")

      Bundler.with_unbundled_env do
        process = IO.popen(
          exec_command.join(" "),
          chdir: repo_path,
          err: [:child, :out],
        )
        body = process.read
        process.close
        body
      end
    end

    before(:all) do
      @repo_path = (Pathname.new(__dir__) / "support" / "repo").expand_path
      Bundler.with_unbundled_env do
        IO.popen(["bundle", "install", "--quiet"], chdir: @repo_path).read
      end
    end

    around(:each) do |&blk|
      FileUtils.rm_rf(T.unsafe(self).repo_path / "sorbet")
      Dir.mktmpdir do |outdir|
        @outdir = outdir
        super(&blk)
      end
      FileUtils.rm_rf(T.unsafe(self).repo_path / "sorbet")
    end
  end
end
