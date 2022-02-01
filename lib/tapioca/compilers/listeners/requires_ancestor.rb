# typed: strict
# frozen_string_literal: true

require "pathname"

module Tapioca
  module Compilers
    module NodeListeners
      class RequiresAncestor < Base
        extend T::Sig

        private

        sig { override.params(event: Tapioca::Compilers::SymbolTableCompiler::ScopeEvent).void }
        def on_scope(event)
          ancestors = Trackers::RequiredAncestor.required_ancestors_by(event.constant)
          ancestors.each do |ancestor|
            next unless ancestor # TODO: We should have a way to warn from here
            event.scope << RBI::RequiresAncestor.new(ancestor.to_s)
          end
        end
      end
    end
  end
end
