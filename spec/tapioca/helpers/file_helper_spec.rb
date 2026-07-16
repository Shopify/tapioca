# typed: true
# frozen_string_literal: true

require "spec_helper"

class Tapioca::FileHelperSpec < Minitest::Spec
  FILENAME = Pathname.new("x.rbi")

  include Tapioca::FileHelper

  describe "#file_diff" do
    it "returns diff when files differ" do
      Dir.mktmpdir do |dir|
        dir = Pathname.new(dir)
        a = dir / "a"
        b = dir / "b"
        a.write("line1\nline2\n")
        b.write("line1\nline3\n")

        result = file_diff(FILENAME, a, b)

        assert_equal(<<~DIFF, result)
          --- Current x.rbi
          +++ Expected x.rbi (After running `bin/tapioca dsl`)
          @@ -1,2 +1,2 @@
           line1
          -line2
          +line3
        DIFF
      end
    end

    it "returns empty string when files are identical" do
      Dir.mktmpdir do |dir|
        dir = Pathname.new(dir)
        a = dir / "a"
        a.write("line1\n")

        assert_equal("", file_diff(FILENAME, a, a))
      end
    end

    it "diffs against null path when a file is added" do
      Dir.mktmpdir do |dir|
        dir = Pathname.new(dir)
        a = dir / "a"
        a.write("line1\n")

        result = file_diff(FILENAME, File::NULL, a)

        assert_equal(<<~DIFF, result)
          --- Current x.rbi
          +++ Expected x.rbi (After running `bin/tapioca dsl`)
          @@ -0,0 +1 @@
          +line1
        DIFF
      end
    end

    it "returns nil when file path is missing" do
      Dir.mktmpdir do |dir|
        dir = Pathname.new(dir)
        a = dir / "a"
        a.write("x\n")

        _out, err = capture_io do
          assert_nil(file_diff(FILENAME, a, "/nonexistent/path"))
        end

        assert_match(/Failed to create x\.rbi diff\./, err)
      end
    end

    it "returns nil when diff is unavailable" do
      _out, err = capture_io do
        Open3.stub(:capture3, ->(*_args) { raise Errno::ENOENT, "diff" }) do
          assert_nil(file_diff(FILENAME, "/a", "/b"))
        end
      end

      assert_match(/Failed to create x\.rbi diff\./, err)
    end

    it "returns nil when the process has no exitstatus" do
      fake_status = Struct.new(:exitstatus).new(nil)

      _out, err = capture_io do
        Open3.stub(:capture3, ->(*_args) { ["", "", fake_status] }) do
          assert_nil(file_diff(FILENAME, "/a", "/b"))
        end
      end

      assert_match(/Failed to create x\.rbi diff\./, err)
    end
  end
end
