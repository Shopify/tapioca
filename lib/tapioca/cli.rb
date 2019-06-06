# frozen_string_literal: true
# typed: false

require 'thor'

module Tapioca
  class Cli < Thor
    class_option :prerequire
    class_option :postrequire
    class_option :outdir, default: "sorbet/rbi/gems"
    class_option :generate_command
    class_option :typed_overrides, type: :hash, default: {}

    desc "generate [gem...]", "generate RBIs from gems"
    def generate(*gems)
      Tapioca.silence_warnings do
        generator.build_gem_rbis(gems)
      end
    end

    desc "bundle", "sync RBIs to Gemfile"
    def bundle
      Tapioca.silence_warnings do
        generator.sync_rbis_with_gemfile
      end
    end

    no_commands do
      def generator
        @generator ||= Generator.new(
          outdir: options[:outdir],
          prerequire: options[:prerequire],
          postrequire: options[:postrequire],
          command: options[:generate_command] || default_command,
          typed_overrides: options[:typed_overrides]
        )
      end

      def default_command
        command = File.basename($PROGRAM_NAME)
        args = ARGV.join(" ")

        "#{command} #{args}"
      end
    end
  end
end
