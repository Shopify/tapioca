# typed: strict
# frozen_string_literal: true

module Tapioca
  class Config < T::Struct
    extend(T::Sig)

    const(:outdir, String)
    const(:prerequire, T.nilable(String))
    const(:postrequire, String)
    const(:generate_command, String)
    const(:typed_overrides, T::Hash[String, String])

    sig { returns(Pathname) }
    def outpath
      @outpath ||= T.let(Pathname.new(outdir), T.nilable(Pathname))
      T.must(@outpath)
    end

    private_class_method :new

    class << self
      extend(T::Sig)

      sig { params(options: T::Hash[String, T.untyped]).returns(T.self_type) }
      def from_options(options)
        Config.from_hash(
          merge_options(default_options, options)
        )
      end

      private

      sig { returns(T::Hash[String, T.untyped]) }
      def default_options
        DEFAULT_OPTIONS
      end

      sig { returns(String) }
      def default_command
        command = File.basename($PROGRAM_NAME)
        args = ARGV.join(" ")

        "#{command} #{args}"
      end

      sig { params(options: T::Hash[String, T.untyped]).returns(T::Hash[String, T.untyped]) }
      def merge_options(*options)
        options.each_with_object({}) do |option, result|
          result.merge!(option) do |_, this_val, other_val|
            if this_val.is_a?(Hash) && other_val.is_a?(Hash)
              this_val.merge(other_val)
            else
              other_val
            end
          end
        end
      end
    end

    SORBET_CONFIG = "sorbet/config"

    DEFAULT_POSTREQUIRE = "sorbet/tapioca/require.rb"
    DEFAULT_OUTDIR = "sorbet/rbi/gems"
    DEFAULT_OVERRIDES = T.let({
      # ActiveSupport overrides some core methods with different signatures
      # so we generate a typed: false RBI for it to suppress errors
      "activesupport" => "false",
    }.freeze, T::Hash[String, String])

    DEFAULT_OPTIONS = T.let({
      "postrequire" => DEFAULT_POSTREQUIRE,
      "outdir" => DEFAULT_OUTDIR,
      "generate_command" => default_command,
      "typed_overrides" => DEFAULT_OVERRIDES,
    }.freeze, T::Hash[String, T.untyped])
  end
end
