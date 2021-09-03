# typed: strong
# frozen_string_literal: true

module Tapioca
  module Compilers
    class SymbolTableCompiler
      extend(T::Sig)

      sig do
        params(
          gem: Gemfile::GemSpec,
          indent: Integer,
          include_docs: T::Boolean
        ).returns(String)
      end
      def compile(
        gem,
        indent = 0,
        include_docs = false
      )
        Tapioca::Compilers::SymbolTable::SymbolGenerator.new(gem, indent, include_docs).generate
      end
    end
  end
end
