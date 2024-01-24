# typed: strict
# frozen_string_literal: true

begin
  gem("graphql", ">= 1.13")
  require "graphql"
rescue LoadError
  return
end

require "tapioca/dsl/helpers/graphql_type_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::GraphqlImplements` generates RBI files for subclasses of
      # [`GraphQL::Schema::Object`](https://graphql-ruby.org/api-doc/2.0.11/GraphQL/Schema/Object)
      # that implement an interface.
      #
      # For example, with the following `GraphQL::Schema::Object` subclass:
      #
      # ~~~rb
      # class Post < GraphQL::Schema::Object
      #   implements Commentable
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   include Commentable
      # end
      # ~~~
      class GraphqlImplements < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(GraphQL::Schema::Object) } }

        sig { override.void }
        def decorate
          root.create_class(constant.name) do |klass|
            constant.own_interface_type_memberships.each do |type_membership|
              klass.create_include(type_membership.abstract_type.name)
            end
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes.select do |c|
              c < GraphQL::Schema::Object && c.own_interface_type_memberships.any?
            end
          end
        end
      end
    end
  end
end
