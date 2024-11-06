# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class SpoomDoc < Base
        extend T::Sig

        private

        sig { override.params(event: ConstNodeAdded).void }
        def on_const(event)
          event.node.comments = documentation_comments(event.symbol)
        end

        sig { override.params(event: ScopeNodeAdded).void }
        def on_scope(event)
          event.node.comments = documentation_comments(event.symbol)
        end

        sig { override.params(event: MethodNodeAdded).void }
        def on_method(event)
          separator = "::" # event.constant.singleton_class? ? "." : "#"
          event.node.comments = documentation_comments(
            "#{event.symbol}#{separator}#{event.node.name}",
            sigs: event.node.sigs,
          )
        end

        sig { params(name: String, sigs: T::Array[RBI::Sig]).returns(T::Array[RBI::Comment]) }
        def documentation_comments(name, sigs: [])
          symbol = @pipeline.model.symbols[name]

          return [] unless symbol

          comments = symbol.definitions.map(&:comments).join("\n")

          [RBI::Comment.new(comments)]
        end

        sig { override.params(event: NodeAdded).returns(T::Boolean) }
        def ignore?(event)
          event.is_a?(Tapioca::Gem::ForeignScopeNodeAdded)
        end
      end
    end
  end
end
