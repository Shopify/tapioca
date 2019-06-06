# frozen_string_literal: true
# typed: false

require 'thor'

module Tapioca
  class Cli < Thor
    class_option :prerequire,
                  aliases: ["--pre", "-b"],
                  banner: "file",
                  desc: "A file to be required before Bundler.require is called"
    class_option :postrequire,
                  aliases: ["--post", "-a"],
                  banner: "file",
                  desc: "A file to be required after Bundler.require is called"
    class_option :outdir,
                  aliases: ["--out", "-o"],
                  default: "sorbet/rbi/gems",
                  banner: "directory",
                  desc: "The output directory for generated RBI files"
    class_option :generate_command,
                  aliases: ["--cmd", "-c"],
                  banner: "command",
                  desc: "The command to run to regenerate RBI files"
    class_option :typed_overrides,
                  aliases: ["--typed", "-t"],
                  type: :hash,
                  default: {},
                  banner: "gem:level",
                  desc: "Overrides for typed sigils for generated gem RBIs"

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
