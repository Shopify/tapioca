# typed: strict
# frozen_string_literal: true

require "pathname"

module Tapioca
  module Gem
    module Plugins
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

        sig { override.params(mod: RBI::Module).void }
        def decorate_module(mod)
          mod.comments = documentation_comments(mod.fully_qualified_name)
        end

        sig { override.params(cls: RBI::Class).void }
        def decorate_class(cls)
          cls.comments = documentation_comments(cls.fully_qualified_name)
        end

        sig { params(const: RBI::Const).void }
        def decorate_const(const)
          const.comments = documentation_comments(const.fully_qualified_name)
        end

        sig { override.params(meth: RBI::Method).void }
        def decorate_method(meth)
          meth.comments = documentation_comments(meth.fully_qualified_name)
        end

        private

        sig { params(name: String).returns(T::Array[RBI::Comment]) }
        def documentation_comments(name)
          name = name.sub(/^::/, "") # RBI namespaces are rooted on `::` while Yard expect them without this prefix

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
