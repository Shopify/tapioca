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
    const(:todos_path, String)

    sig { returns(Pathname) }
    def outpath
      @outpath = T.let(@outpath, T.nilable(Pathname))
      @outpath ||= Pathname.new(outdir)
    end

    private_class_method :new

    TAPIOCA_PATH = T.let("sorbet/tapioca", String)
    CONFIG_FILE_PATH = T.let("#{TAPIOCA_PATH}/config.yml", String)
    SORBET_CONFIG = T.let("sorbet/config", String)

    DEFAULT_POSTREQUIRE = T.let("#{TAPIOCA_PATH}/require.rb", String)
    DEFAULT_RBIDIR = "sorbet/rbi"
    DEFAULT_OUTDIR = T.let("#{DEFAULT_RBIDIR}/gems", String)
    DEFAULT_OVERRIDES = T.let({
      # ActiveSupport overrides some core methods with different signatures
      # so we generate a typed: false RBI for it to suppress errors
      "activesupport" => "false",
    }.freeze, T::Hash[String, String])
    DEFAULT_TODOSPATH = T.let("#{DEFAULT_RBIDIR}/todo.rbi", String)
  end
end
