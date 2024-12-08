# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveRecord::Base)

require "tapioca/dsl/helpers/active_record_constants_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveRecordScope` decorates RBI files for
      # subclasses of `ActiveRecord::Base` which declare
      # [`scope` fields](https://api.rubyonrails.org/classes/ActiveRecord/Scoping/Named/ClassMethods.html#method-i-scope).
      #
      # For example, with the following `ActiveRecord::Base` subclass:
      #
      # ~~~rb
      # class Post < ApplicationRecord
      #   scope :public_kind, -> { where.not(kind: 'private') }
      #   scope :private_kind, -> { where(kind: 'private') }
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   extend GeneratedRelationMethods
      #
      #   module GeneratedRelationMethods
      #     sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
      #     def private_kind(*args, &blk); end
      #
      #     sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
      #     def public_kind(*args, &blk); end
      #   end
      # end
      # ~~~
      class ActiveRecordScope < Compiler
        extend T::Sig
        include Helpers::ActiveRecordConstantsHelper

        ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

        sig { override.void }
        def decorate
          scope_method_names, class_method_names = gather_method_names

          return if scope_method_names.empty? && class_method_names.empty?

          root.create_path(constant) do |model|
            relation_methods_module = model.create_module(RelationMethodsModuleName)

            if compiler_enabled?("ActiveRecordRelations")
              assoc_relation_methods_module = model.create_module(AssociationRelationMethodsModuleName)

              generate_scope_methods(relation_methods_module, scope_method_names, RelationClassName)
              generate_class_methods(relation_methods_module, class_method_names)
              generate_scope_methods(assoc_relation_methods_module, scope_method_names, AssociationRelationClassName)
              generate_class_methods(assoc_relation_methods_module, class_method_names)
            else
              generate_scope_methods(relation_methods_module, scope_method_names, "T.untyped")
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

        sig { returns([T::Array[Symbol], T::Array[Symbol]]) }
        def gather_method_names
          scope_methods = T.let([], T::Array[Symbol])
          class_methods = T.let([], T::Array[Symbol])
          constant = self.constant

          # Keep gathering scope methods until we hit "ActiveRecord::Base"
          until constant == ActiveRecord::Base
            # we are guaranteed to have a superclass that is of type "ActiveRecord::Base"
            superclass = T.cast(T.must(superclass_of(constant)), T.class_of(ActiveRecord::Base))

            scope_methods.concat(constant.send(:generated_relation_methods).instance_methods(false))
            class_methods.concat(constant.methods(false) - superclass.methods(false) - scope_methods)

            constant = superclass
          end

          [scope_methods.uniq, class_methods.uniq]
        end

        sig do
          params(
            mod: RBI::Scope,
            scope_methods: T::Array[Symbol],
            return_type: String,
          ).void
        end
        def generate_scope_methods(mod, scope_methods, return_type)
          scope_methods.each do |scope_method|
            mod.create_method(
              scope_method.to_s,
              parameters: [
                create_rest_param("args", type: "T.untyped"),
                create_block_param("blk", type: "T.untyped"),
              ],
              return_type: return_type,
            )
          end
        end

        sig { params(mod: RBI::Scope, class_methods: T::Array[Symbol]).void }
        def generate_class_methods(mod, class_methods)
          class_methods.each do |class_method|
            create_method_from_def(mod, constant.public_method(class_method))
          end
        end
      end
    end
  end
end
