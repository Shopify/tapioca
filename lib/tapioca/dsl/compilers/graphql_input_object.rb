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
      # `Tapioca::Dsl::Compilers::GraphqlInputObject` generates RBI files for subclasses of
      # [`GraphQL::Schema::InputObject`](https://graphql-ruby.org/api-doc/2.0.11/GraphQL/Schema/InputObject).
      #
      # For example, with the following `GraphQL::Schema::InputObject` subclass:
      #
      # ~~~rb
      # class CreateCommentInput < GraphQL::Schema::InputObject
      #   argument :body, String, required: true
      #   argument :post_id, ID, required: true
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `notify_user_job.rbi` with the following content:
      #
      # ~~~rbi
      # # create_comment.rbi
      # # typed: true
      # class CreateCommentInput
      #   sig { returns(String) }
      #   def body; end
      #
      #   sig { returns(String) }
      #   def post_id; end
      # end
      # ~~~
      class GraphqlInputObject < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(GraphQL::Schema::InputObject) } }

        sig { override.void }
        def decorate
          graphql_gem = T.must(Gemfile.new([]).gem("graphql"))

          # Skip methods explicitly defined in code
          arguments = constant.all_argument_definitions.select do |argument|
            source_location = constant.instance_method(argument.keyword.to_s).source_location&.first
            source_location && graphql_gem.contains_path?(source_location)
          end
          return if arguments.empty?

          root.create_path(constant) do |input_object|
            arguments.each do |argument|
              name = argument.keyword.to_s
              input_object.create_method(name, return_type: Helpers::GraphqlTypeHelper.type_for(argument.type))
            end
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes.select { |c| c < GraphQL::Schema::InputObject }
          end
        end
      end
    end
  end
end
