# typed: strict
# frozen_string_literal: true

require "tapioca/generators/base_generator"

module Tapioca
  module Generators
    class TodoGenerator < BaseGenerator
      extend(T::Sig)

      sig { override.void }
      def generate
        build_todos
      end

      sig { override.params(error: String).void }
      def error_handler(error)
      end

      private

      sig { void }
      def build_todos
        todos_path = config.todos_path
        compiler = Compilers::TodosCompiler.new

        # Clean all existing unresolved constants before regenerating the list
        # so Sorbet won't grab them as already resolved.
        File.delete(todos_path) if File.exist?(todos_path)

        rbi_string = compiler.compile
        return if rbi_string.empty?

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
      end
    end
  end
end
