# typed: strong
# frozen_string_literal: true

module Tapioca
  module Compilers
    class SymbolTableCompiler
      extend(T::Sig)

      sig { params(gem: Gemfile::GemSpec, rbi: RBI::File, indent: Integer, include_docs: T::Boolean).void }
      def compile(gem, rbi, indent = 0, include_docs = false)
        Tapioca::Compilers::SymbolTable::SymbolGenerator
          .new(gem, indent, include_docs)
          .generate(rbi)
      end
    end
  end
end
