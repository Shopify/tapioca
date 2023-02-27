# typed: strict
# frozen_string_literal: true

begin
  require "active_record"
rescue LoadError
  return
end

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
          method_names = scope_method_names

          return if method_names.empty?

          relation_methods_module = model.create_module(RelationMethodsModuleName)
          create_relation_class

          method_names.each do |scope_method|
            generate_scope_method(
              relation_methods_module,
              scope_method.to_s,
              relations_enabled? ? RelationClassName : "T.untyped",
            )

            assoc_relation_methods_mod = association_relation_methods_module
            next unless assoc_relation_methods_mod

            generate_scope_method(
              assoc_relation_methods_mod,
              scope_method.to_s,
              AssociationRelationClassName,
            )
          end

          model.create_extend(RelationMethodsModuleName)
        end

        class << self
          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            descendants_of(::ActiveRecord::Base)
          end
        end

        private

        sig { returns(RBI::Scope) }
        def model
          @model ||= T.let(
            root.create_path(constant),
            T.nilable(RBI::Scope),
          )
        end

        sig { returns(T::Boolean) }
        def relations_enabled?
          compiler_enabled?("ActiveRecordRelations")
        end

        sig { returns(T.nilable(RBI::Scope)) }
        def association_relation_methods_module
          @association_relation_methods_module ||= T.let(
            model.create_module(AssociationRelationMethodsModuleName),
            T.nilable(RBI::Scope),
          ) if relations_enabled? && !constant.abstract_class?
        end

        sig { void }
        def create_relation_class
          return unless relations_enabled? && constant.abstract_class?

          superclass = "::ActiveRecord::Relation"

          model.create_class(RelationClassName, superclass_name: superclass) do |klass|
            klass.create_include(RelationMethodsModuleName)
          end
        end

        sig { returns(T::Array[Symbol]) }
        def scope_method_names
          scope_methods = T.let([], T::Array[Symbol])
          constant = self.constant

          # Keep gathering scope methods until we hit "ActiveRecord::Base"
          until constant == ActiveRecord::Base
            scope_methods.concat(constant.send(:generated_relation_methods).instance_methods(false))

            superclass = superclass_of(constant)
            break unless superclass

            # we are guaranteed to have a superclass that is of type "ActiveRecord::Base"
            constant = T.cast(superclass, T.class_of(ActiveRecord::Base))
          end

          scope_methods
        end

        sig do
          params(
            mod: RBI::Scope,
            scope_method: String,
            return_type: String,
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
