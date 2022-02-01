# typed: strict
# frozen_string_literal: true

require "pathname"

module Tapioca
  module Compilers
    module NodeListeners
      class DynamicMixins < Base
        extend T::Sig

        include Reflection

        private

        sig { override.params(event: Tapioca::Compilers::SymbolTableCompiler::NodeEvent).void }
        def on_node(event)
          node = event.node
          constant = event.constant
          return if constant.is_a?(Class)

          case node
          when RBI::Scope
            mixin_compiler = DynamicMixinCompiler.new(constant)
            mixin_compiler.compile_class_attributes(node)
            dynamic_extends, dynamic_includes = mixin_compiler.compile_mixes_in_class_methods(node)

            (dynamic_includes + dynamic_extends).each do |mod|
              name = name_of(mod)
              @compiler.push_symbol(node, name) if name
            end
          end
        end
      end
    end
  end
end
