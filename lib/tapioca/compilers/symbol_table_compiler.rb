# typed: strong
# frozen_string_literal: true

module Tapioca
  module Compilers
    class SymbolTableCompiler
      extend(T::Sig)

      sig { params(gem: Gemfile::GemSpec, indent: Integer, include_docs: T::Boolean).returns(RBI::Tree) }
      def compile(gem, indent = 0, include_docs = false)
        rbi_file = RBI::File.new(strictness: "true")
        Tapioca::Compilers::SymbolTable::SymbolGenerator
          .new(gem, indent, include_docs)
          .generate(rbi_file.root)
      end
    end
  end
end
