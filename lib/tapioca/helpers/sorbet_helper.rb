# typed: strict
# frozen_string_literal: true

module Tapioca
  module SorbetHelper
    extend T::Sig

    SORBET_GEM_SPEC = T.let(
      ::Gem::Specification.find_by_name("sorbet-static"),
      ::Gem::Specification,
    )

    SORBET_BIN = T.let(
      Pathname.new(SORBET_GEM_SPEC.full_gem_path) / "libexec" / "sorbet",
      Pathname,
    )

    SORBET_EXE_PATH_ENV_VAR = "TAPIOCA_SORBET_EXE"

    SORBET_PAYLOAD_URL = "https://github.com/sorbet/sorbet/tree/master/rbi"

    FEATURE_REQUIREMENTS = T.let({
      type_variable_block_syntax: ::Gem::Requirement.new(">= 0.5.9892"), # https://github.com/sorbet/sorbet/pull/5639
    }.freeze, T::Hash[Symbol, ::Gem::Requirement])

    sig { params(sorbet_args: String).returns(Spoom::ExecResult) }
    def sorbet(*sorbet_args)
      Spoom::Sorbet.srb(sorbet_args.join(" "), sorbet_bin: sorbet_path, capture_err: true)
    end

    sig { returns(String) }
    def sorbet_path
      sorbet_path = ENV.fetch(SORBET_EXE_PATH_ENV_VAR, SORBET_BIN)
      sorbet_path = SORBET_BIN if sorbet_path.empty?
      sorbet_path.to_s.shellescape
    end

    sig { params(feature: Symbol, version: T.nilable(::Gem::Version)).returns(T::Boolean) }
    def sorbet_supports?(feature, version: nil)
      version = SORBET_GEM_SPEC.version unless version
      requirement = FEATURE_REQUIREMENTS[feature]

      Kernel.raise "Invalid Sorbet feature #{feature}" unless requirement

      requirement.satisfied_by?(version)
    end
  end
end
