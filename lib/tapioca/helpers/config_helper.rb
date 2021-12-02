# typed: strict
# frozen_string_literal: true

require "yaml"

module Tapioca
  module ConfigHelper
    extend T::Sig

    SORBET_PATH = T.let("sorbet", String)
    SORBET_CONFIG = T.let("#{SORBET_PATH}/config", String)
    TAPIOCA_PATH = T.let("#{SORBET_PATH}/tapioca", String)
    TAPIOCA_CONFIG = T.let("#{TAPIOCA_PATH}/config.yml", String)

    DEFAULT_COMMAND = T.let("bin/tapioca", String)
    DEFAULT_POSTREQUIRE = T.let("#{TAPIOCA_PATH}/require.rb", String)
    DEFAULT_RBIDIR = T.let("#{SORBET_PATH}/rbi", String)
    DEFAULT_DSLDIR = T.let("#{DEFAULT_RBIDIR}/dsl", String)
    DEFAULT_GEMDIR = T.let("#{DEFAULT_RBIDIR}/gems", String)
    DEFAULT_SHIMDIR = T.let("#{DEFAULT_RBIDIR}/shims", String)
    DEFAULT_TODOSPATH = T.let("#{DEFAULT_RBIDIR}/todo.rbi", String)

    DEFAULT_OVERRIDES = T.let({
      # ActiveSupport overrides some core methods with different signatures
      # so we generate a typed: false RBI for it to suppress errors
      "activesupport" => "false",
    }.freeze, T::Hash[String, String])

    sig { returns(String) }
    attr_reader :command_name

    sig { params(args: T.untyped, local_options: T.untyped, config: T.untyped).void }
    def initialize(args = [], local_options = {}, config = {})
      # Store current command
      command = config[:current_command]
      command_options = config[:command_options]
      @command_name = T.let(command.name, String)
      @merged_options = T.let(nil, T.nilable(Thor::CoreExt::HashWithIndifferentAccess))
      @defaults = T.let(nil, T.nilable(Thor::CoreExt::HashWithIndifferentAccess))

      # Filter command options unless we are handling the help command.
      # This is so that the defaults are printed
      filter_defaults(command_options) unless command_name == "help"

      # Call original initialize method
      super
    end

    sig { returns(Thor::CoreExt::HashWithIndifferentAccess) }
    def options
      @merged_options ||= begin
        original_options = super
        config_options = config_options(original_options)

        merge_options(defaults, config_options, original_options)
      end
    end

    private

    sig { params(options: T::Hash[Symbol, Thor::Option]).void }
    def filter_defaults(options)
      options.each do |key, option|
        # Store the value of the current default in our defaults hash
        defaults[key] = option.default
        # Remove the default value from the option
        option.instance_variable_set(:@default, nil)
      end
    end

    sig { returns(Thor::CoreExt::HashWithIndifferentAccess) }
    def defaults
      @defaults ||= Thor::CoreExt::HashWithIndifferentAccess.new
    end

    sig { params(options: Thor::CoreExt::HashWithIndifferentAccess).returns(Thor::CoreExt::HashWithIndifferentAccess) }
    def config_options(options)
      config_file = options[:config]
      config = {}

      if File.exist?(config_file)
        config = YAML.load_file(config_file, fallback: {})
      end

      Thor::CoreExt::HashWithIndifferentAccess.new(config[command_name] || {})
    end

    sig do
      params(options: T.nilable(Thor::CoreExt::HashWithIndifferentAccess))
        .returns(Thor::CoreExt::HashWithIndifferentAccess)
    end
    def merge_options(*options)
      options.each_with_object(Thor::CoreExt::HashWithIndifferentAccess.new) do |option, result|
        result.merge!(option || {}) do |_, this_val, other_val|
          if this_val.is_a?(Hash) && other_val.is_a?(Hash)
            Thor::CoreExt::HashWithIndifferentAccess.new(this_val.merge(other_val))
          else
            other_val
          end
        end
      end
    end
  end
end
