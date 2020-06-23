# typed: true
# frozen_string_literal: true

require "parlour"

begin
  require "active_record"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::Dsl::ActiveRecordScope` decorates RBI files for subclasses of
      # `ActiveRecord::Base` which declare `scope` fields
      # (see https://api.rubyonrails.org).
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
      #   extend Post::GeneratedRelationMethods
      # end
      #
      # module Post::GeneratedRelationMethods
      #   sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
      #   def private_kind(*args, &blk); end

      #   sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
      #   def public_kind(*args, &blk); end
      # end
      # ~~~
      class ActiveRecordScope < Base
        extend T::Sig

        sig do
          override.params(
            root: Parlour::RbiGenerator::Namespace,
            constant: T.class_of(::ActiveRecord::Base)
          ).void
        end
        def decorate(root, constant)
          scope_method_names = constant.send(:generated_relation_methods).instance_methods(false)
          return if scope_method_names.empty?

          module_name = "#{constant}::GeneratedRelationMethods"
          root.create_module(module_name) do |mod|
            scope_method_names.each do |scope_method|
              generate_scope_method(scope_method, mod)
            end
          end

          root.path(constant) do |k|
            k.create_extend(module_name)
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          ::ActiveRecord::Base.descendants.reject(&:abstract_class?)
        end

        private

        sig do
          params(
            scope_method: String,
            mod: Parlour::RbiGenerator::Namespace,
          ).void
        end
        def generate_scope_method(scope_method, mod)
          # This return type should actually be Model::ActiveRecord_Relation
          return_type = "T.untyped"

          create_method(
            mod,
            scope_method,
            parameters: [
              Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped"),
              Parlour::RbiGenerator::Parameter.new("&blk", type: "T.untyped"),
            ],
            return_type: return_type,
          )
        end
      end
    end
  end
end
