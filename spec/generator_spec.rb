# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  class GeneratorSpec < Minitest::HooksSpec
    attr_reader :outdir
    attr_reader :repo_path

    before(:all) do
      @repo_path = (Pathname.new(__dir__) / "support" / "repo").expand_path
    end

    around(:each) do |&blk|
      Dir.mktmpdir do |outdir|
        @outdir = outdir
        super(&blk)
      end
    end
  end
end
