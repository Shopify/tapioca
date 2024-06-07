# typed: strict
# frozen_string_literal: true

require "tapioca/internal"

module RubyLsp
  module Tapioca
    class Client
      extend T::Sig

      sig { void }
      def initialize
        $stderr.puts "Initializing client"
      end

      sig { void }
      def sync_gems
        $stderr.puts "Sync gems"
      end

      sig { params(constants: T::Array[String]).void }
      def dsl(constants)
        $stderr.puts "DSL"
        $stderr.puts constants
      end

      sig { params(paths: T::Array[String]).void }
      def dsl_with_path(paths)
        $stderr.puts "DSL"
        $stderr.puts paths

        command = ::Tapioca::Commands::DslGenerate.new(
          requested_constants: [],
          tapioca_path: ::Tapioca::TAPIOCA_DIR,
          requested_paths: paths.map { |p| Pathname.new(p) },
          outpath: Pathname.new(::Tapioca::DEFAULT_DSL_DIR),
          file_header: true,
          exclude: [],
          only: [],
        )

        Thread.new do
          $stderr.puts "Running DslGenerate from new thread"
          $stdout.reopen("/dev/null", "w") # VSCode can't deal with stdout puts
          command.run
          $stderr.puts "Done DslGenerate"
        end
      end
    end
  end
end
