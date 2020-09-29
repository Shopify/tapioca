# typed: strong
# frozen_string_literal: true

module Tapioca
  module Compilers
    # Taken from https://github.com/sorbet/sorbet/blob/master/gems/sorbet/lib/todo-rbi.rb
    class TodosCompiler
      extend(T::Sig)

      sig do
        returns(String)
      end
      def compile
        list_todos.each_line.map do |line|
          next if line.include?("<") || line.include?("class_of")
          "module #{line.strip.gsub('T.untyped::', '')}; end"
        end.compact.join("\n")
      end

      private

      sig { returns(String) }
      def list_todos
        Tapioca::Compilers::Sorbet.run(
          "--print=missing-constants",
          "--stdout-hup-hack",
          "--no-error-count"
        ).strip
      end
    end
  end
end
