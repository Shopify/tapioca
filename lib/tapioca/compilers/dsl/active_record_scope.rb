# typed: strict
# frozen_string_literal: true

begin
  require "active_record"
rescue LoadError
  return
end

require "tapioca/compilers/dsl/helper/active_record_constants"

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::Dsl::ActiveRecordScope` decorates RBI files for
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
      # this generator will produce the RBI file `post.rbi` with the following content:
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
      class ActiveRecordScope < Base
        extend T::Sig
        include Helper::ActiveRecordConstants

        sig do
          override.params(
            root: RBI::Tree,
            constant: T.class_of(::ActiveRecord::Base)
          ).void
        end
        def decorate(root, constant)
          method_names = scope_method_names(constant)

          return if method_names.empty?

          root.create_path(constant) do |model|
            relation_methods_module = model.create_module(RelationMethodsModuleName)
            association_relation_methods_module = model.create_module(AssociationRelationMethodsModuleName)

            method_names.each do |scope_method|
              generate_scope_method(
                relation_methods_module,
                scope_method.to_s,
                RelationClassName
              )
              generate_scope_method(
                association_relation_methods_module,
                scope_method.to_s,
                AssociationRelationClassName
              )
            end

            model.create_extend(RelationMethodsModuleName)
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          descendants_of(::ActiveRecord::Base).reject(&:abstract_class?)
        end

        private

        sig { params(constant: T.class_of(::ActiveRecord::Base)).returns(T::Array[Symbol]) }
        def scope_method_names(constant)
          scope_methods = T.let([], T::Array[Symbol])

          # Keep gathering scope methods until we hit "ActiveRecord::Base"
          until constant == ActiveRecord::Base
            scope_methods.concat(constant.send(:generated_relation_methods).instance_methods(false))

            # we are guaranteed to have a superclass that is of type "ActiveRecord::Base"
            constant = T.cast(constant.superclass, T.class_of(ActiveRecord::Base))
          end

          scope_methods
        end

        sig do
          params(
            mod: RBI::Scope,
            scope_method: String,
            return_type: String
          ).void
        end
        def generate_scope_method(mod, scope_method, return_type)
          mod.create_method(
            scope_method,
            parameters: [
              create_rest_param("args", type: "T.untyped"),
              create_block_param("blk", type: "T.untyped"),
            ],
            return_type: return_type,
          )
        end
      end
    end
  end
end
