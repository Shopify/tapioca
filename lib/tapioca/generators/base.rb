# typed: strict
# frozen_string_literal: true

# TODO: Remove me when logging logic has been abstracted.
require "thor"

module Tapioca
  module Generators
    class Base
      extend T::Sig
      extend T::Helpers

      class FileWriter < Thor
        include Thor::Actions
      end

      # TODO: Remove me when logging logic has been abstracted
      include Thor::Base

      abstract!

      sig { params(default_command: String, file_writer: Thor::Actions).void }
      def initialize(default_command:, file_writer: FileWriter.new)
        @file_writer = file_writer
        @default_command = default_command
      end

      sig { abstract.void }
      def generate; end

      private

      # TODO: Remove me when logging logic has been abstracted
      sig { params(message: String, color: T.any(Symbol, T::Array[Symbol])).void }
      def say_error(message = "", *color)
        force_new_line = (message.to_s !~ /( |\t)\Z/)
        # NOTE: This is a hack. We're no longer subclassing from Thor::Shell::Color
        # so we no longer have access to the prepare_message call.
        # We should update this to remove this.
        buffer = shell.send(:prepare_message, *T.unsafe([message, *T.unsafe(color)]))
        buffer << "\n" if force_new_line && !message.to_s.end_with?("\n")

        $stderr.print(buffer)
        $stderr.flush
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
        @file_writer.create_file(path, force: force, skip: skip, verbose: verbose) { content }
      end
    end
  end
end
