# typed: true
# frozen_string_literal: true

require "pathname"
require "shellwords"

module Tapioca
  module Compilers
    module Sorbet
      SORBET = Pathname.new(Gem::Specification.find_by_name("sorbet-static").full_gem_path) / "libexec" / "sorbet"
      EXE_PATH_ENV_VAR = "TAPIOCA_SORBET_EXE"

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
      end
    end
  end
end
