# typed: strict
# frozen_string_literal: true

module Tapioca
  class Config < T::Struct
    extend(T::Sig)

    const(:outdir, String)
    const(:prerequire, T.nilable(String))
    const(:postrequire, String)
    const(:generate_command, String)
    const(:exclude, T::Array[String])
    const(:typed_overrides, T::Hash[String, String])

    sig { returns(Pathname) }
    def outpath
      @outpath ||= T.let(Pathname.new(outdir), T.nilable(Pathname))
      T.must(@outpath)
    end

    private_class_method :new

    CONFIG_FILE_PATH = "sorbet/tapioca/config.yml"
    SORBET_CONFIG = "sorbet/config"

    DEFAULT_POSTREQUIRE = "sorbet/tapioca/require.rb"
    DEFAULT_OUTDIR = "sorbet/rbi/gems"
    DEFAULT_OVERRIDES = T.let({
      # ActiveSupport overrides some core methods with different signatures
      # so we generate a typed: false RBI for it to suppress errors
      "activesupport" => "false",
    }.freeze, T::Hash[String, String])
  end
end
