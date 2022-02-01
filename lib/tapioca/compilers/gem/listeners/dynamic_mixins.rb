# typed: strict
# frozen_string_literal: true

module Tapioca
  module Compilers
    module Gem
      module Listeners
        class DynamicMixins < Base
          extend T::Sig

          include Reflection

          private

          sig { override.params(event: NewScopeNode).void }
          def on_scope(event)
            constant = event.constant
            return if constant.is_a?(Class)

            node = event.node
            mixin_compiler = DynamicMixinCompiler.new(constant)
            mixin_compiler.compile_class_attributes(node)
            dynamic_extends, dynamic_includes = mixin_compiler.compile_mixes_in_class_methods(node)

            (dynamic_includes + dynamic_extends).each do |mod|
              name = name_of(mod)
              @compiler.push_symbol(name) if name
            end
          end
        end
      end
    end
  end
end
