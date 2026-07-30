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
    # A digest mismatch deletes Bootsnap's cache payload and records the new
    # digest, so this run rebuilds the cache from scratch.
    module BootsnapCache
      DIGEST_FILE = ".gemfile-lock-digest" #: String

      class << self
        #: (String) -> void
        def prepare_for_setup(cache_dir)
          digest = gemfile_lock_digest
          return if digest_matches?(cache_dir, digest)

          FileUtils.rm_rf(File.join(cache_dir, "bootsnap"))
          FileUtils.mkdir_p(cache_dir)
          File.write(digest_path(cache_dir), digest)
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
