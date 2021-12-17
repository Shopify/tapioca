# typed: strict
# frozen_string_literal: true

require "yaml"

module Tapioca
  module ConfigHelper
    extend T::Sig

    sig { returns(String) }
    attr_reader :command_name

    sig { returns(Thor::CoreExt::HashWithIndifferentAccess) }
    attr_reader :defaults

    sig { params(args: T.untyped, local_options: T.untyped, config: T.untyped).void }
    def initialize(args = [], local_options = {}, config = {})
      # Store current command
      command = config[:current_command]
      command_options = config[:command_options]
      @command_name = T.let(command.name, String)
      @merged_options = T.let(nil, T.nilable(Thor::CoreExt::HashWithIndifferentAccess))
      @defaults = T.let(Thor::CoreExt::HashWithIndifferentAccess.new, Thor::CoreExt::HashWithIndifferentAccess)

      # Filter command options unless we are handling the help command.
      # This is so that the defaults are printed
      filter_defaults(command_options) unless command_name == "help"

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
      merged = options.each_with_object({}) do |option, result|
        result.merge!(option || {}) do |_, this_val, other_val|
          if this_val.is_a?(Hash) && other_val.is_a?(Hash)
            Thor::CoreExt::HashWithIndifferentAccess.new(this_val.merge(other_val))
          else
            other_val
          end
        end
      end

      Thor::CoreExt::HashWithIndifferentAccess.new(merged)
    end
  end
end
