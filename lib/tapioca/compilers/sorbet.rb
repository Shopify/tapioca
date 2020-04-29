# frozen_string_literal: true
# typed: true

require 'pathname'
require 'shellwords'

module Tapioca
  module Compilers
    module Sorbet
      SORBET = Pathname.new(Gem::Specification.find_by_name("sorbet-static").full_gem_path) / "libexec" / "sorbet"

      class << self
        extend(T::Sig)

        sig { params(args: String).returns(String) }
        def run(*args)
          IO.popen(
            [
              sorbet_path,
              "--quiet",
              *args,
            ].join(' '),
            err: "/dev/null"
          ).read
        end

        sig { returns(String) }
        def sorbet_path
          SORBET.to_s.shellescape
        end
      end
    end
  end
end
