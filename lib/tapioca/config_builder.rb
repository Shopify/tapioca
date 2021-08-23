# typed: strict
# frozen_string_literal: true

require "yaml"

module Tapioca
  class ConfigBuilder
    class << self
      extend(T::Sig)

      sig { params(command: Symbol, options: T::Hash[String, T.untyped]).returns(Config) }
      def from_options(command, options)
        merged_options = merge_options(default_options(command), config_options, options)

        puts(<<~MSG) if merged_options.include?("generate_command")
          DEPRECATION: The `-c` and `--cmd` flags will be removed in a future release.
        MSG

        Config.from_hash(merged_options)
      end

      private

      sig { returns(T::Hash[String, T.untyped]) }
      def config_options
        if File.exist?(Config::TAPIOCA_CONFIG)
          YAML.load_file(Config::TAPIOCA_CONFIG, fallback: {})
        else
          {}
        end
      end

      sig { params(command: Symbol).returns(T::Hash[String, T.untyped]) }
      def default_options(command)
        default_outdir = case command
        when :sync, :generate, :gem
          Config::DEFAULT_GEMDIR
        when :dsl
          Config::DEFAULT_DSLDIR
        else
          Config::SORBET_PATH
        end

        DEFAULT_OPTIONS.merge("outdir" => default_outdir)
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
      "outdir" => nil,
      "exclude" => [],
      "exclude_generators" => [],
      "typed_overrides" => Config::DEFAULT_OVERRIDES,
      "todos_path" => Config::DEFAULT_TODOSPATH,
      "generators" => [],
      "file_header" => true,
    }.freeze, T::Hash[String, T.untyped])
  end
end
