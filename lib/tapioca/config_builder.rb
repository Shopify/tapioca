# typed: strict
# frozen_string_literal: true

module Tapioca
  class ConfigBuilder
    class << self
      extend(T::Sig)

      sig { params(options: T::Hash[String, T.untyped]).returns(Config) }
      def from_options(options)
        Config.from_hash(
          merge_options(default_options, config_options, options)
        )
      end

      private

      sig { returns(T::Hash[String, T.untyped]) }
      def config_options
        if File.exist?(Config::CONFIG_FILE_PATH)
          YAML.load_file(Config::CONFIG_FILE_PATH, fallback: {})
        else
          {}
        end
      end

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

    DEFAULT_OPTIONS = T.let({
      "postrequire" => Config::DEFAULT_POSTREQUIRE,
      "outdir" => Config::DEFAULT_OUTDIR,
      "generate_command" => default_command,
      "typed_overrides" => Config::DEFAULT_OVERRIDES,
    }.freeze, T::Hash[String, T.untyped])
  end
end
