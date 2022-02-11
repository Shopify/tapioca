# typed: strict
# frozen_string_literal: true

require "pathname"
require "shellwords"

module Tapioca
  module SorbetHelper
    extend T::Sig

    SORBET_GEM_SPEC = T.let(
      ::Gem::Specification.find_by_name("sorbet-static"),
      ::Gem::Specification
    )

    SORBET_BIN = T.let(
      Pathname.new(SORBET_GEM_SPEC.full_gem_path) / "libexec" / "sorbet",
      Pathname
    )

    SORBET_EXE_PATH_ENV_VAR = "TAPIOCA_SORBET_EXE"

    FEATURE_REQUIREMENTS = T.let({
      # First tag that includes https://github.com/sorbet/sorbet/pull/4706
      to_ary_nil_support: ::Gem::Requirement.new(">= 0.5.9220"),
    }.freeze, T::Hash[Symbol, ::Gem::Requirement])

    class CmdResult < T::Struct
      const :out, String
      const :err, String
      const :status, T::Boolean
    end

    sig { params(sorbet_args: String).returns(CmdResult) }
    def sorbet(*sorbet_args)
      out, err, status = Open3.capture3([sorbet_path, *sorbet_args].join(" "))
      CmdResult.new(out: out, err: err, status: status.success? || false)
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
