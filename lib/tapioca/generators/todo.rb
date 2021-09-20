# typed: strict
# frozen_string_literal: true

module Tapioca
  module Generators
    class Todo < Base
      sig { void }
      def build_todos
        todos_path = config.todos_path
        compiler = Compilers::TodosCompiler.new
        name = set_color(todos_path, :yellow, :bold)
        say("Compiling #{name}, this may take a few seconds... ")

        # Clean all existing unresolved constants before regenerating the list
        # so Sorbet won't grab them as already resolved.
        File.delete(todos_path) if File.exist?(todos_path)

        rbi_string = compiler.compile
        if rbi_string.empty?
          say("Nothing to do", :green)
          return
        end

        content = String.new
        content << rbi_header(
          "#{Config::DEFAULT_COMMAND} todo",
          reason: "unresolved constants",
          strictness: "false"
        )
        content << rbi_string
        content << "\n"

        outdir = File.dirname(todos_path)
        FileUtils.mkdir_p(outdir)
        File.write(todos_path, content)

        say("Done", :green)

        say("All unresolved constants have been written to #{name}.", [:green, :bold])
        say("Please review changes and commit them.", [:green, :bold])
      end

      sig { params(command: String, reason: T.nilable(String), strictness: T.nilable(String)).returns(String) }
      def rbi_header(command, reason: nil, strictness: nil)
        statement = <<~HEAD
          # DO NOT EDIT MANUALLY
          # This is an autogenerated file for #{reason}.
          # Please instead update this file by running `#{command}`.
        HEAD

        sigil = <<~SIGIL if strictness
          # typed: #{strictness}
        SIGIL

        if config.file_header
          [statement, sigil].compact.join("\n").strip.concat("\n\n")
        elsif sigil
          sigil.strip.concat("\n\n")
        else
          ""
        end
      end
    end
  end
end
