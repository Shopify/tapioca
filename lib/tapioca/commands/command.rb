# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    # @abstract
    class Command
      extend T::Sig
      class FileWriter < Thor
        include Thor::Actions
      end

      include Thor::Base
      include CliHelper

      #: -> void
      def initialize
        @file_writer = FileWriter.new #: Thor::Actions
      end

      # @final
      #: -> void
      def run
        Tapioca.silence_warnings do
          execute
        end
      end

      private

      # @abstract
      #: -> void
      def execute = raise NotImplementedError, "Abstract method called"

      #: (Symbol command, *String args) -> String
      def default_command(command, *args)
        [Tapioca::BINARY_FILE, command.to_s, *args].join(" ")
      end

      #: Thor::Actions
      attr_reader :file_writer

      #: ((String | Pathname) path, String content, ?force: bool, ?skip: bool, ?verbose: bool) -> void
      def create_file(path, content, force: true, skip: false, verbose: true)
        file_writer.create_file(path, force: force, skip: skip, verbose: verbose) { content }
      end

      #: ((String | Pathname) path, ?verbose: bool) -> void
      def remove_file(path, verbose: true)
        file_writer.remove_file(path, verbose: verbose)
      end
    end
  end
end
