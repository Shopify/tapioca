# typed: strict
# frozen_string_literal: true

require "pathname"

module Tapioca
  module Compilers
    module NodeListeners
      class YardDoc < Base
        extend T::Sig

        IGNORED_COMMENTS = T.let([
          ":doc:",
          ":nodoc:",
          "typed:",
          "frozen_string_literal:",
          "encoding:",
          "warn_indent:",
          "shareable_constant_value:",
          "rubocop:",
        ], T::Array[String])

        private

        sig { override.params(event: Tapioca::Compilers::SymbolTableCompiler::ConstEvent).void }
        def on_const(event)
          event.const.comments = documentation_comments(event.symbol)
        end

        sig { override.params(event: Tapioca::Compilers::SymbolTableCompiler::ScopeEvent).void }
        def on_scope(event)
          event.scope.comments = documentation_comments(event.symbol)
        end

        sig { override.params(event: Tapioca::Compilers::SymbolTableCompiler::MethodEvent).void }
        def on_method(event)
          separator = event.constant.singleton_class? ? "." : "#"
          event.node.comments = documentation_comments("#{event.symbol}#{separator}#{event.node.name}")
        end

        sig { params(name: String).returns(T::Array[RBI::Comment]) }
        def documentation_comments(name)
          yard_docs = YARD::Registry.at(name)
          return [] unless yard_docs

          docstring = yard_docs.docstring
          return [] if /(copyright|license)/i.match?(docstring)

          docstring.lines
            .reject { |line| IGNORED_COMMENTS.any? { |comment| line.include?(comment) } }
            .map! { |line| RBI::Comment.new(line) }
        end
      end
    end
  end
end
