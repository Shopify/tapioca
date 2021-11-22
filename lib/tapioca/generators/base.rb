# typed: strict
# frozen_string_literal: true

module Tapioca
  module Generators
    class Base
      extend T::Sig
      extend T::Helpers

      class FileWriter < Thor
        include Thor::Actions
      end

      include CliHelper
      include Thor::Base # TODO: Remove me when logging logic has been abstracted

      abstract!

      sig { params(default_command: String, file_writer: Thor::Actions).void }
      def initialize(default_command:, file_writer: FileWriter.new)
        @file_writer = file_writer
        @default_command = default_command
      end

      sig { abstract.void }
      def generate; end

      private

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
        @file_writer.create_file(path, force: force, skip: skip, verbose: verbose) { content }
      end

      sig do
        params(
          path: T.any(String, Pathname),
          verbose: T::Boolean
        ).void
      end
      def remove_file(path, verbose: true)
        @file_writer.remove_file(path, verbose: verbose)
      end
    end
  end
end
