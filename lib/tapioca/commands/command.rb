# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class Command
      extend T::Sig
      extend T::Helpers

      class FileWriter < Thor
        include Thor::Actions
      end

      include Thor::Base
      include CliHelper

      abstract!

      sig { abstract.void }
      def execute; end

      private

      sig { params(command: Symbol, args: String).returns(String) }
      def default_command(command, *args)
        [Tapioca::DEFAULT_COMMAND, command.to_s, *args].join(" ")
      end

      sig { returns(Thor::Actions) }
      def file_writer
        FileWriter.new
      end

      sig do
        params(
          path: T.any(String, Pathname),
          content: String,
          force: T::Boolean,
          skip: T::Boolean,
          verbose: T::Boolean
        ).void
      end
      def create_file(path, content, force: true, skip: false, verbose: true)
        file_writer.create_file(path, force: force, skip: skip, verbose: verbose) { content }
      end

      sig do
        params(
          path: T.any(String, Pathname),
          verbose: T::Boolean
        ).void
      end
      def remove_file(path, verbose: true)
        file_writer.remove_file(path, verbose: verbose)
      end
    end
  end
end
