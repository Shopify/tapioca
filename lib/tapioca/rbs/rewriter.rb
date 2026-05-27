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

  require "require-hooks/setup"
else
  require "require-hooks/setup"

  begin
    # Disable Bootsnap's iseq cache unless TAPIOCA_RBS_CACHE=1 enabled the separate cache above.
    #
    # This is necessary because host apps can call Bootsnap.setup after tapioca loads this file. When that happens,
    # Bootsnap installs `load_iseq` and serves files from its cache, which bypasses RequireHooks.source_transform.
    # Preloading bootsnap's iseq support lets us override `load_iseq` before setup installs it, preserving the default
    # RBS rewrite behavior at the cost of slower app boot.
    require "bootsnap"
    require "bootsnap/compile_cache/iseq"

    module Bootsnap
      module CompileCache
        module ISeq
          module InstructionSequenceMixin
            #: (String) -> RubyVM::InstructionSequence
            def load_iseq(path)
              super if defined?(super) # Disable Bootsnap's hook, but trigger any others.
            end
          end
        end
      end
    end
  rescue LoadError
    # Bootsnap is not in the bundle, we don't need to do anything.
  end
end

# We need to include `T::Sig` very early to make sure that the `sig` method is available since gems using RBS comments
# are unlikely to include `T::Sig` in their own classes.
Module.include(T::Sig)

# Trigger the source transformation for each Ruby file being loaded.
RequireHooks.source_transform(patterns: ["**/*.rb"]) do |path, source|
  # The source is most likely nil since no `source_transform` hook was triggered before this one.
  source ||= File.read(path, encoding: "UTF-8")

  # For performance reasons, we only rewrite files that use Sorbet.
  if source =~ /^\s*#\s*typed: (ignore|false|true|strict|strong|__STDLIB_INTERNAL)/
    # Sorbet runtime only supports one signature per method, so keep the last overload.
    Spoom::Sorbet::Translate.rbs_comments_to_sorbet_sigs(source, file: path, overloads_strategy: :translate_last)
  end
rescue Spoom::Sorbet::Translate::Error
  # If we can't translate the RBS comments back into Sorbet's signatures, we just skip the file.
  source
end
