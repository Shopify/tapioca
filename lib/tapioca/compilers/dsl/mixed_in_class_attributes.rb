# typed: strict
# frozen_string_literal: true

begin
  require "active_support/core_ext/class/attribute"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::Dsl::MixedInClassAttributes` generates RBI files for modules that dynamically use
      # `class_attribute` on classes.
      #
      # For example, given the following concern
      #
      # ~~~rb
      # module Taggeable
      #   extend ActiveSupport::Concern
      #
      #   included do
      #     class_attribute :tag
      #   end
      # end
      # ~~~
      #
      # this generator will produce the RBI file `taggeable.rbi` with the following content:
      #
      # ~~~rbi
      # # typed: strong
      #
      # module Taggeable
      #   include GeneratedInstanceMethods
      #
      #   mixes_in_class_methods GeneratedClassMethods
      #
      #   module GeneratedClassMethods
      #     def tag; end
      #     def tag=(value); end
      #     def tag?; end
      #   end
      #
      #   module GeneratedInstanceMethods
      #     def tag; end
      #     def tag=(value); end
      #     def tag?; end
      #   end
      # end
      # ~~~
      class MixedInClassAttributes < Base
        extend T::Sig

        sig { override.params(root: RBI::Tree, constant: Module).void }
        def decorate(root, constant)
          mixin_compiler = DynamicMixinCompiler.new(constant)
          return if mixin_compiler.empty_attributes?

          root.create_path(constant) do |mod|
            mixin_compiler.compile_class_attributes(mod)
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          # Select all non-anonymous modules that have overridden Module.included
          all_modules.select do |mod|
            !mod.is_a?(Class) && name_of(mod) && Tapioca::Reflection.method_of(mod, :included).owner != Module
          end
        end
      end
    end
  end
end
