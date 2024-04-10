# typed: strict
# frozen_string_literal: true

return unless defined?(ViewComponent)

module Tapioca
  module Dsl
    module Compilers
      # Generates RBI for ViewComponent::Slotable
      # See https://github.com/ViewComponent/view_component/blob/main/lib/view_component/slotable.rb
      class ViewComponentSlotables < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::ViewComponent::Slotable) } }

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes
              .select { |c| c < ViewComponent::Slotable && c.name != "ViewComponent::Base" }
          end
        end

        sig { override.void }
        def decorate
          root.create_path(constant) do |klass|
            T.unsafe(constant).registered_slots.each do |name, config|
              renderable_type = config[:renderable]
              renderable = T.let(
                case renderable_type
                when String
                  renderable_type
                when Class
                  T.must(renderable_type.name)
                else
                  "T.untyped"
                end,
                String,
              )

              is_many = T.let(config[:collection], T::Boolean)
              return_type =
                if is_many
                  "T::Enumerable[#{renderable}]"
                else
                  renderable
                end

              module_name = "ViewComponentSlotablesMethodsModule"
              klass.create_module(module_name) do |mod|
                generate_instance_methods(mod, name.to_s, return_type, is_many)
              end
              klass.create_include(module_name)
            end
          end
        end

        sig { params(klass: RBI::Scope, name: String, return_type: String, is_many: T::Boolean).void }
        def generate_instance_methods(klass, name, return_type, is_many)
          klass.create_method(name, return_type: return_type)
          klass.create_method("#{name}?", return_type: "T::Boolean")

          klass.create_method(
            "with_#{name}",
            parameters: [
              create_rest_param("args", type: "T.untyped"),
              create_block_param("block", type: "T.untyped"),
            ],
            return_type: "T.untyped",
          )

          if is_many
            # For collection subcomponents, ViewComponent generates methods for the singular version
            # of the name.
            singular_name = ActiveSupport::Inflector.singularize(name)

            klass.create_method(
              "with_#{singular_name}",
              parameters: [
                create_rest_param("args", type: "T.untyped"),
                create_block_param("block", type: "T.untyped"),
              ],
              return_type: "T.untyped",
            )
            klass.create_method(
              "with_#{singular_name}_content",
              parameters: [
                create_param("content", type: "T.untyped"),
              ],
              return_type: "T.untyped",
            )

          else
            klass.create_method(
              "with_#{name}_content",
              parameters: [
                create_param("content", type: "T.untyped"),
              ],
              return_type: "T.untyped",
            )
          end
        end
      end
    end
  end
end
