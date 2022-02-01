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

        sig { override.params(event: Tapioca::Compilers::SymbolTableCompiler::NodeEvent).void }
        def on_node(event)
          node = event.node

          case node
          when RBI::Module, RBI::Class, RBI::Const
            node.comments = documentation_comments(event.symbol)
          when RBI::Method
            separator = event.constant.singleton_class? ? "." : "#"
            comments = documentation_comments("#{event.symbol}#{separator}#{node.name}")
            node.comments = comments
          end
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
