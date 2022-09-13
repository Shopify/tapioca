# typed: strict
# frozen_string_literal: true

begin
  require "graphql"
rescue LoadError
  return
end

require "tapioca/dsl/helpers/graphql_type_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::GraphqlMutation` generates RBI files for subclasses of
      # [`GraphQL::Schema::Mutation`](https://graphql-ruby.org/api-doc/2.0.11/GraphQL/Schema/Mutation).
      #
      # For example, with the following `GraphQL::Schema::Mutation` subclass:
      #
      # ~~~rb
      # class CreateComment < GraphQL::Schema::Mutation
      #   argument :body, String, required: true
      #   argument :post_id, ID, required: true
      #
      #   def resolve(body:, post_id:)
      #     # ...
      #   end
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `notify_user_job.rbi` with the following content:
      #
      # ~~~rbi
      # # create_comment.rbi
      # # typed: true
      # class CreateComment
      #   sig { params(body: String, post_id: String).returns(T.untyped) }
      #   def resolve(body:, post_id:); end
      # end
      # ~~~
      class GraphqlMutation < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(GraphQL::Schema::InputObject) } }

        sig { override.void }
        def decorate
          return unless constant.method_defined?(:resolve)

          method_def = constant.instance_method(:resolve)
          return if signature_of(method_def) # Skip if the mutation already has an inline sig

          arguments = constant.all_argument_definitions
          return if arguments.empty?

          arguments_by_name = arguments.to_h { |a| [a.keyword.to_s, a] }

          params = compile_method_parameters_to_rbi(method_def).map do |param|
            name = param.param.name
            argument = arguments_by_name.fetch(name, nil)
            create_typed_param(param.param, argument ? Helpers::GraphqlTypeHelper.type_for(argument.type) : "T.untyped")
          end

          root.create_path(constant) do |mutation|
            mutation.create_method("resolve", parameters: params, return_type: "T.untyped")
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes.select { |c| c < GraphQL::Schema::Mutation && c != GraphQL::Schema::RelayClassicMutation }
          end
        end
      end
    end
  end
end
