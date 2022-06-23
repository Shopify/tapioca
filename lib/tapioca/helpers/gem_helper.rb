# typed: true
# frozen_string_literal: true

module Tapioca
  module GemHelper
    extend T::Sig

    sig { params(gemfile_dir: String, full_gem_path: String).returns(T::Boolean) }
    def gem_in_app_dir?(gemfile_dir, full_gem_path)
      !gem_in_bundle_path?(to_realpath(full_gem_path)) &&
        full_gem_path.start_with?(to_realpath(gemfile_dir))
    end

    sig { params(full_gem_path: String).returns(T::Boolean) }
    def gem_in_bundle_path?(full_gem_path)
      full_gem_path.start_with?(Bundler.bundle_path.to_s, Bundler.app_cache.to_s)
    end

    sig { params(path: T.any(String, Pathname)).returns(String) }
    def to_realpath(path)
      path_string = path.to_s
      path_string = File.realpath(path_string) if File.exist?(path_string)
      path_string
    end
  end
end
