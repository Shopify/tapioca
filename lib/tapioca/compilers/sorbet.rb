# typed: true
# frozen_string_literal: true

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
          custom_sorbet_path = ENV["TPC_SORBET_EXE"]
          if custom_sorbet_path.nil? || custom_sorbet_path.empty?
            SORBET.to_s.shellescape
          else
            custom_sorbet_path.shellescape
          end
        end
      end
    end
  end
end
