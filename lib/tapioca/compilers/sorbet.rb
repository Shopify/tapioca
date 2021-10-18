# typed: strict
# frozen_string_literal: true

require "pathname"
require "shellwords"

module Tapioca
  module Compilers
    module Sorbet
      SORBET_GEM_SPEC = T.let(
        Gem::Specification.find_by_name("sorbet-static"),
        Gem::Specification
      )
      SORBET = T.let(
        Pathname.new(SORBET_GEM_SPEC.full_gem_path) / "libexec" / "sorbet",
        Pathname
      )
      EXE_PATH_ENV_VAR = "TAPIOCA_SORBET_EXE"

      FEATURE_REQUIREMENTS = T.let({
        # First tag that includes https://github.com/sorbet/sorbet/pull/4706
        to_ary_nil_support: Gem::Requirement.new(">= 0.5.9220"),
      }.freeze, T::Hash[Symbol, Gem::Requirement])

      class << self
        extend(T::Sig)

        sig { params(args: String).returns(String) }
        def run(*args)
          IO.popen(
            [
              sorbet_path,
              "--quiet",
              *args,
            ].join(" "),
            err: "/dev/null"
          ).read
        end

        sig { returns(String) }
        def sorbet_path
          sorbet_path = ENV.fetch(EXE_PATH_ENV_VAR, SORBET)
          sorbet_path = SORBET if sorbet_path.empty?
          sorbet_path.to_s.shellescape
        end

        sig { params(feature: Symbol, version: T.nilable(Gem::Version)).returns(T::Boolean) }
        def supports?(feature, version: nil)
          version = SORBET_GEM_SPEC.version unless version
          requirement = FEATURE_REQUIREMENTS[feature]

          raise "Invalid Sorbet feature #{feature}" unless requirement

          requirement.satisfied_by?(version)
        end
      end
    end
  end
end
