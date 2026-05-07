# typed: strict
# frozen_string_literal: true

# This code rewrites RBS comments back into Sorbet's signatures as the files are being loaded.
# This will allow `sorbet-runtime` to wrap the methods as if they were originally written with the `sig{}` blocks.
# This will in turn allow Tapioca to use this signatures to generate typed RBI files.

module Tapioca
  module RBS
    class HostBootsnapSetupError < StandardError; end

    # Raises when the host calls `Bootsnap.setup` after tapioca's setup. Host's call
    # would overwrite tapioca's cache directory, so rewritten iseqs would end up in
    # the host's regular cache.
    module BootsnapGuard
      extend T::Sig

      sig { params(_kwargs: T.untyped).void }
      def setup(**_kwargs)
        Kernel.raise HostBootsnapSetupError, <<~MSG
          Bootsnap.setup was called while TAPIOCA_RBS_CACHE=1 is set. Tapioca already
          configured bootsnap with a dedicated cache directory; re-running setup
          would overwrite that config and start writing rewritten iseqs into your
          host's cache.

          Gate your host's Bootsnap.setup on the env var, e.g. in config/boot.rb:

            require "bootsnap/setup" unless ENV["TAPIOCA_RBS_CACHE"] == "1"
        MSG
      end
    end
  end
end

# When TAPIOCA_RBS_CACHE=1, set up bootsnap with a dedicated cache directory
# and load require-hooks so the RBS-rewritten iseqs get cached. Subsequent
# runs read the rewritten iseq directly and skip the rewrite.
#
# After our setup, BootsnapGuard is prepended so the host application can't
# replace our cache directory.
if ENV["TAPIOCA_RBS_CACHE"] == "1"
  begin
    require "bootsnap"
    # Respect BOOTSNAP_READONLY for consumers reading a pre-populated cache
    # (e.g. a CI prime step).
    readonly = !["0", "false", false].include?(ENV.fetch("BOOTSNAP_READONLY") { false })
    Bootsnap.setup(
      cache_dir: ENV.fetch("TAPIOCA_BOOTSNAP_CACHE_DIR", File.join(Dir.pwd, "tmp/cache/bootsnap-tapioca-rbs")),
      development_mode: true,
      load_path_cache: true,
      compile_cache_iseq: true,
      compile_cache_yaml: true,
      readonly: readonly,
      revalidation: true,
    )
    Bootsnap.log_stats!
    Bootsnap.singleton_class.prepend(Tapioca::RBS::BootsnapGuard)
  rescue LoadError
    # Bootsnap is not in the bundle, skip iseq caching.
  end
end

require "require-hooks/setup"

module Tapioca
  module RBS
    module Rewriter
      TYPED_FILE_PATTERN = /^\s*#\s*typed: (ignore|false|true|strict|strong|__STDLIB_INTERNAL)/
      # Markers consumed by Spoom's RBS comment rewriter beyond `#:`/`#|`.
      # Keep in sync with Spoom: missing markers skip rewrites; extra markers only add safe false positives.
      RBS_ANNOTATION_MARKERS = [
        "# @abstract",
        "# @interface",
        "# @sealed",
        "# @final",
        "# @requires_ancestor:",
        "# @override",
        "# @overridable",
        "# @without_runtime",
      ].freeze #: Array[String]
      RBS_REWRITE_PATTERN = Regexp.union(["#:", "#|"] + RBS_ANNOTATION_MARKERS).freeze #: Regexp

      class << self
        #: (String source) -> bool
        def typed_file?(source)
          source.match?(TYPED_FILE_PATTERN)
        end

        #: (String source) -> bool
        def possible_rbs_runtime_rewrite_syntax?(source)
          source.match?(RBS_REWRITE_PATTERN)
        end

        #: (untyped path, String source) -> String?
        def rewrite(path, source)
          return unless typed_file?(source)
          return source unless possible_rbs_runtime_rewrite_syntax?(source)

          Spoom::Sorbet::Translate.rbs_comments_to_sorbet_sigs(source, file: path)
        rescue Spoom::Sorbet::Translate::Error
          # If we can't translate the RBS comments back into Sorbet's signatures, we just skip the file.
          source
        end
      end
    end
  end
end

# We need to include `T::Sig` very early to make sure that the `sig` method is available since gems using RBS comments
# are unlikely to include `T::Sig` in their own classes.
Module.include(T::Sig)

# Trigger the source transformation for each Ruby file being loaded.
RequireHooks.source_transform(patterns: ["**/*.rb"]) do |path, source|
  # The source is most likely nil since no `source_transform` hook was triggered before this one.
  source ||= File.read(path, encoding: "UTF-8")

  Tapioca::RBS::Rewriter.rewrite(path, source)
end
