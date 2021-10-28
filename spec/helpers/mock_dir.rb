# typed: strict
# frozen_string_literal: true

require "fileutils"

module Tapioca
  # A directory used to represent either a mock project or a mock gem
  class MockDir
    extend T::Sig

    # The absolute path to this directory
    sig { returns(String) }
    attr_reader :path

    # Create a new directory at `path`
    #
    # Warning: if `path` already exists, it will be deleted.
    sig { params(path: String).void }
    def initialize(path)
      @path = path
      FileUtils.rm_rf(@path)
      FileUtils.mkdir_p(@path)
    end

    # Create an absolute path from `self.path` and `rel_path`
    sig { params(rel_path: String).returns(String) }
    def absolute_path(rel_path)
      (Pathname.new(path) / rel_path).to_s
    end

    # Write `contents` in the file at `rel_path`
    #
    # All parent directories up to `rel_path` will be created.
    # If `append` is `true`, the the `contents` will be appended to the file.
    sig { params(rel_path: String, contents: String, append: T::Boolean).void }
    def write(rel_path, contents = "", append: false)
      path = absolute_path(rel_path)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, contents, mode: append ? "a" : "w")
    end

    # Read contents from the file at `rel_path`
    sig { params(rel_path: String).returns(String) }
    def read(rel_path)
      File.read(absolute_path(rel_path))
    end

    # Does `rel_path` point to an existing file?
    sig { params(rel_path: String).returns(T::Boolean) }
    def file?(rel_path)
      File.file?(absolute_path(rel_path))
    end

    # List all files (recursively) in this directory
    sig { returns(T::Array[String]) }
    def files
      Dir.glob("#{@path}/**/*").sort
    end

    # Remove the file or directory at `rel_path`
    sig { params(rel_path: String).void }
    def remove(rel_path)
      FileUtils.rm_rf(absolute_path(rel_path))
    end

    # Move the file or directory from `from_rel_path` to `to_rel_path`
    sig { params(from_rel_path: String, to_rel_path: String).void }
    def move(from_rel_path, to_rel_path)
      FileUtils.mv(absolute_path(from_rel_path), absolute_path(to_rel_path))
    end

    # Delete this directory and all its contents
    sig { void }
    def destroy
      FileUtils.rm_rf(path)
    end
  end
end
