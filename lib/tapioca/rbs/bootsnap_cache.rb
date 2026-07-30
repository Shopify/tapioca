# typed: strict
# frozen_string_literal: true

require "bundler"
require "digest"
require "fileutils"

module Tapioca
  module RBS
    # Prepares the Bootsnap iseq cache used for RBS rewrite output.
    #
    # RBS rewrite output can change when the lockfile changes, even if the
    # source files are unchanged.
    # To account for this, we store the current Gemfile.lock SHA256 in a
    # `.gemfile-lock-digest` file.
    # On writable runs, a digest mismatch deletes Bootsnap's cache payload and
    # records the new digest, so this run rebuilds the cache from scratch. On
    # read-only runs, a digest mismatch means the cache is stale and must not be
    # used.
    module BootsnapCache
      PrepareResult = Struct.new(:setup_bootsnap, keyword_init: true)

      DIGEST_FILE = ".gemfile-lock-digest" #: String

      class << self
        #: (String, readonly: bool) -> PrepareResult
        def prepare_for_setup(cache_dir, readonly:)
          digest = gemfile_lock_digest

          if readonly
            return PrepareResult.new(setup_bootsnap: digest_matches?(cache_dir, digest))
          end

          unless digest_matches?(cache_dir, digest)
            FileUtils.rm_rf(File.join(cache_dir, "bootsnap"))
            FileUtils.mkdir_p(cache_dir)
            File.write(digest_path(cache_dir), digest)
          end

          PrepareResult.new(setup_bootsnap: true)
        end

        private

        #: -> String
        def gemfile_lock_digest
          Digest::SHA256.file(Bundler.default_lockfile).hexdigest
        end

        #: (String, String) -> bool
        def digest_matches?(cache_dir, digest)
          path = digest_path(cache_dir)
          File.file?(path) && File.read(path).chomp == digest
        end

        #: (String) -> String
        def digest_path(cache_dir)
          File.join(cache_dir, DIGEST_FILE)
        end
      end
    end
  end
end
