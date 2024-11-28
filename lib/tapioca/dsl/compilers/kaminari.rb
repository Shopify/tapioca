# typed: strict
# frozen_string_literal: true

return unless defined?(Kaminari)

require "tapioca/dsl/helpers/active_record_constants_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::Kaminari` decorates RBI files for models
      # using Kaminari.
      #
      # For example, with Kaminari installed and the following `ActiveRecord::Base` subclass:
      #
      # ~~~rb
      # class Post < ApplicationRecord
      # end
      # ~~~
      #
      # This compiler will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   extend GeneratedRelationMethods
      #
      #   module GeneratedRelationMethods
      #     sig do
      #       params(
      #         num: T.any(Integer, String)
      #       ).returns(T.all(PrivateRelation, Kaminari::PageScopeMethods, Kaminari::ActiveRecordRelationMethods))
      #     end
      #     def page(num = nil); end
      #   end
      # end
      # ~~~
      class Kaminari < Compiler
        extend T::Sig
        include Helpers::ActiveRecordConstantsHelper

        ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

        sig { override.void }
        def decorate
          root.create_path(constant) do |model|
            target_modules.each do |module_name, return_type|
              model.create_module(module_name).create_method(
                ::Kaminari.config.page_method_name.to_s,
                parameters: [create_opt_param("num", type: "T.any(Integer, String)", default: "nil")],
                return_type: "T.all(#{return_type}, Kaminari::PageScopeMethods, Kaminari::ActiveRecordRelationMethods)",
              )
            end

            model.create_extend(RelationMethodsModuleName)
          end
        end

        class << self
          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            descendants_of(::ActiveRecord::Base).reject(&:abstract_class?)
          end
        end

        private

        sig { returns(T::Array[[String, String]]) }
        def target_modules
          if compiler_enabled?("ActiveRecordRelations")
            [
              [RelationMethodsModuleName, RelationClassName],
              [AssociationRelationMethodsModuleName, AssociationRelationClassName],
            ]
          else
            [[RelationMethodsModuleName, "T.untyped"]]
          end
        end
      end
    end
  end
end
