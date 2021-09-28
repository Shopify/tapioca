# typed: strict
# frozen_string_literal: true

require "tapioca/rbi_ext/header"

module Tapioca
  module Generators
    class Todo < Base
      include RBI::Header

      sig { params(todos_path: String, file_header: T::Boolean, default_command: String).void }
      def initialize(todos_path:, file_header:, default_command:)
        @todos_path = todos_path
        @file_header = file_header

        super(default_command: default_command)
      end

      sig { override.void }
      def generate
        compiler = Compilers::TodosCompiler.new
        name = set_color(@todos_path, :yellow, :bold)
        say("Compiling #{name}, this may take a few seconds... ")

        # Clean all existing unresolved constants before regenerating the list
        # so Sorbet won't grab them as already resolved.
        File.delete(@todos_path) if File.exist?(@todos_path)

        rbi_string = compiler.compile
        if rbi_string.empty?
          say("Nothing to do", :green)
          return
        end

        content = String.new
        content << rbi_header(
          "#{@default_command} todo",
          reason: "unresolved constants",
          strictness: "false",
          show_file_header: @file_header
        )
        content << rbi_string
        content << "\n"

        outdir = File.dirname(@todos_path)
        FileUtils.mkdir_p(outdir)
        File.write(@todos_path, content)

        say("Done", :green)

        say("All unresolved constants have been written to #{name}.", [:green, :bold])
        say("Please review changes and commit them.", [:green, :bold])
      end
    end
  end
end
