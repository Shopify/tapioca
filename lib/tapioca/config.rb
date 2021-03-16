# typed: strict
# frozen_string_literal: true

module Tapioca
  class Config < T::Struct
    extend(T::Sig)

    const(:outdir, String)
    const(:prerequire, T.nilable(String))
    const(:postrequire, String)
    const(:exclude, T::Array[String])
    const(:typed_overrides, T::Hash[String, String])
    const(:todos_path, String)
    const(:generators, T::Array[String])

    sig { returns(Pathname) }
    def outpath
      @outpath = T.let(@outpath, T.nilable(Pathname))
      @outpath ||= Pathname.new(outdir)
    end

    private_class_method :new

    SORBET_PATH = T.let("sorbet", String)
    SORBET_CONFIG = T.let("#{SORBET_PATH}/config", String)
    TAPIOCA_PATH = T.let("#{SORBET_PATH}/tapioca", String)
    TAPIOCA_CONFIG = T.let("#{TAPIOCA_PATH}/config.yml", String)

    DEFAULT_COMMAND = T.let("bin/tapioca", String)
    DEFAULT_POSTREQUIRE = T.let("#{TAPIOCA_PATH}/require.rb", String)
    DEFAULT_RBIDIR = T.let("#{SORBET_PATH}/rbi", String)
    DEFAULT_DSLDIR = T.let("#{DEFAULT_RBIDIR}/dsl", String)
    DEFAULT_GEMDIR = T.let("#{DEFAULT_RBIDIR}/gems", String)
    DEFAULT_TODOSPATH = T.let("#{DEFAULT_RBIDIR}/todo.rbi", String)

    DEFAULT_OVERRIDES = T.let({
      # ActiveSupport overrides some core methods with different signatures
      # so we generate a typed: false RBI for it to suppress errors
      "activesupport" => "false",
    }.freeze, T::Hash[String, String])
  end
end
