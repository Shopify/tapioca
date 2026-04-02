# typed: true
# frozen_string_literal: true

require "spec_helper"

# RBI file helpers require Thor as an ancestor. However, including Thor mutates
# the including class's initialize method to expect Thor command args, which trips
# up Minitest's test creation. Since we just want to test the helper methods, we
# can bypass Thor's initialize method and create tests directly
module TestFriendlyThor
  include Thor::Base

  def initialize(name)
    Minitest::Runnable.instance_method(:initialize).bind(self).call(name)
  end
end

class Tapioca::RBIFilesHelperSpec < Minitest::Spec
  include TestFriendlyThor
  include Tapioca::SorbetHelper
  include Tapioca::RBIFilesHelper

  describe "#file_diff" do
    it "returns diff when files differ" do
      Dir.mktmpdir do |dir|
        a = File.join(dir, "a")
        b = File.join(dir, "b")
        File.write(a, "line1\nline2\n")
        File.write(b, "line1\nline3\n")

        result = file_diff(Pathname.new("x.rbi"), a, b)

        assert_includes(result, "--- x.rbi")
        assert_includes(result, "+++ x.rbi")
        assert_includes(result, "-line2")
        assert_includes(result, "+line3")
      end
    end

    it "returns empty string when files are identical" do
      Dir.mktmpdir do |dir|
        a = File.join(dir, "a")
        File.write(a, "line1\n")

        assert_equal("", file_diff(Pathname.new("x.rbi"), a, a))
      end
    end

    it "diffs against null path when a file is added" do
      Dir.mktmpdir do |dir|
        a = File.join(dir, "a")
        File.write(a, "line1\n")

        result = file_diff(Pathname.new("x.rbi"), File::NULL, a)

        assert_includes(result, "+++ x.rbi")
        assert_includes(result, "+line1")
      end
    end

    it "returns empty string when file path is missing" do
      Dir.mktmpdir do |dir|
        a = File.join(dir, "a")
        File.write(a, "x\n")

        _out, err = capture_io do
          assert_equal("", file_diff(Pathname.new("x.rbi"), a, "/nonexistent/path"))
        end

        assert_match(/Failed to create x\.rbi diff\./, err)
      end
    end

    it "returns empty string when diff is unavailable" do
      _out, err = capture_io do
        Open3.stub(:capture3, ->(*_args) { raise Errno::ENOENT, "diff" }) do
          assert_equal("", file_diff(Pathname.new("x.rbi"), "/a", "/b"))
        end
      end

      assert_match(/Failed to create x\.rbi diff\./, err)
    end

    it "returns empty string when the process has no exitstatus" do
      fake_status = Struct.new(:exitstatus).new(nil)

      _out, err = capture_io do
        Open3.stub(:capture3, ->(*_args) { ["", "", fake_status] }) do
          assert_equal("", file_diff(Pathname.new("x.rbi"), "/a", "/b"))
        end
      end

      assert_match(/Failed to create x\.rbi diff\./, err)
    end
  end
end
