# typed: strict
# frozen_string_literal: true

require "require-hooks/setup"

# This code rewrites RBS comments back into Sorbet's signatures as the files are being loaded.
# This will allow `sorbet-runtime` to wrap the methods as if they were originally written with the `sig{}` blocks.
# This will in turn allow Tapioca to use this signatures to generate typed RBI files.

begin
  # When in a `bootsnap` environment, files are loaded from the cache and won't trigger the `source_transform` method.
  # The `require-hooks` gem comes with a `bootsnap` mode that will disable the `bootsnap/compile_cache/iseq` caching.
  # Sadly, we're way to early in the boot process to use it as bootsnap won't be loaded yet and the `require-hooks`
  # setup won't pick it up.
  #
  # As a workaround, if we can preemptively require `bootsnap` and `bootsnap/compile_cache/iseq` we manually override
  # the `load_iseq` method to disable the caching mechanism.
  #
  # This will make the Rails app load slower but allows us to trigger the RBS -> RBI source transform.
  require "bootsnap"
  require "bootsnap/compile_cache/iseq"

  module Bootsnap
    module CompileCache
      module ISeq
        module InstructionSequenceMixin
          #: (String) -> RubyVM::InstructionSequence
          def load_iseq(path)
            super if defined?(super)
          end
        end
      end
    end
  end
rescue LoadError
  # Bootsnap is not in the bundle, we don't need to do anything.
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
    Spoom::Sorbet::Translate.rbs_comments_to_sorbet_sigs(source, file: path)
  end
rescue Spoom::Sorbet::Translate::Error
  # If we can't translate the RBS comments back into Sorbet's signatures, we just skip the file.
  source
end
