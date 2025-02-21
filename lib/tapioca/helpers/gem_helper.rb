# typed: true
# frozen_string_literal: true

module Tapioca
  module GemHelper
    extend T::Sig

    #: ((String | Pathname) app_dir, String full_gem_path) -> bool
    def gem_in_app_dir?(app_dir, full_gem_path)
      app_dir = to_realpath(app_dir)
      full_gem_path = to_realpath(full_gem_path)

      !gem_in_bundle_path?(full_gem_path) && !gem_in_ruby_path?(full_gem_path) && path_in_dir?(full_gem_path, app_dir)
    end

    #: (String full_gem_path) -> bool
    def gem_in_bundle_path?(full_gem_path)
      path_in_dir?(full_gem_path, Bundler.bundle_path) || path_in_dir?(full_gem_path, Bundler.app_cache)
    end

    #: (String full_gem_path) -> bool
    def gem_in_ruby_path?(full_gem_path)
      path_in_dir?(full_gem_path, RbConfig::CONFIG["rubylibprefix"])
    end

    #: ((String | Pathname) path) -> String
    def to_realpath(path)
      path_string = path.to_s
      path_string = File.realpath(path_string) if File.exist?(path_string)
      path_string
    end

    private

    #: ((Pathname | String) path, (Pathname | String) dir) -> bool
    def path_in_dir?(path, dir)
      dir = Pathname.new(dir)
      path = Pathname.new(path)

      path.ascend.any?(dir)
    end
  end
end
