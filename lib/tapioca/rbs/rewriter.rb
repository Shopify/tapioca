# typed: strict
# frozen_string_literal: true

# This code rewrites RBS comments back into Sorbet's signatures as the files are being loaded.
# This will allow `sorbet-runtime` to wrap the methods as if they were originally written with the `sig{}` blocks.
# This will in turn allow Tapioca to use this signatures to generate typed RBI files.

# When TAPIOCA_RBS_CACHE=1, configure bootsnap with iseq caching enabled and
# writable, then load require-hooks/setup so it auto-picks bootsnap mode and
# prepends CompileCacheExt#input_to_storage on Bootsnap::CompileCache::ISeq.
# That prepend runs source_transforms on every cache miss, so the cached iseq
# is the *post-RBS-rewrite* version. Subsequent runs with the same cache_dir
# skip the rewrite entirely.
#
# The host app must also skip its own Bootsnap.setup under this flag,
# otherwise it'll override our settings during Rails boot.
if ENV["TAPIOCA_RBS_CACHE"] == "1"
  begin
    require "bootsnap"
    # Respect BOOTSNAP_READONLY for consumers reading a cache populated
    # elsewhere (e.g., a prime step in CI). String env vars are coerced
    # properly because RTEST("false") would otherwise be truthy.
    readonly_env = ENV["BOOTSNAP_READONLY"]
    readonly = !readonly_env.nil? && !["0", "false"].include?(readonly_env)
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
  rescue LoadError
    # bootsnap not in the bundle — fall through; require-hooks will still load
    # source_transforms via load_iseq mode (slower, no iseq caching).
  end
end

require "require-hooks/setup"

# We need to include `T::Sig` very early to make sure that the `sig` method is available since gems using RBS comments
# are unlikely to include `T::Sig` in their own classes.
Module.include(T::Sig)

# Trigger the source transformation for each Ruby file being loaded.
RequireHooks.source_transform(patterns: ["**/*.rb"]) do |path, source|
  # The source is most likely nil since no `source_transform` hook was triggered before this one.
  source ||= File.read(path, encoding: "UTF-8")

  # For performance reasons, we only rewrite files that use Sorbet.
  if source =~ /^\s*#\s*typed: (ignore|false|true|strict|strong|__STDLIB_INTERNAL)/
    Spoom::Sorbet::Translate.rbs_comments_to_sorbet_sigs(source, file: path)
  end
rescue Spoom::Sorbet::Translate::Error
  # If we can't translate the RBS comments back into Sorbet's signatures, we just skip the file.
  source
end
