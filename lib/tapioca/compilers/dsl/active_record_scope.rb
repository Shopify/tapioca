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
      # end
      # ~~~
      #
      # this generator will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
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
          scopes = constant.send(:generated_relation_methods).instance_methods(false)
          return if scopes.blank?
          module_name = "#{constant}::GeneratedRelationMethods"
          root.create_module(module_name) do |mod|
            generate_instance_methods(constant, mod)
          end

          root.path(constant) do |k|
            k.create_include(module_name)

            # scopes.each do |scope, value|
            #   create_method(k, scope.to_s, class_method: true, return_type: "T.untyped")
            # end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          ::ActiveRecord::Base.descendants.reject(&:abstract_class?)
        end

        private

        sig do
          params(
            constant: T.class_of(::ActiveRecord::Base),
            klass: Parlour::RbiGenerator::Namespace,
          ).void
        end
        def generate_instance_methods(constant, klass)
          methods = constant.send(:generated_relation_methods).instance_methods(false)
          methods.each do |method|
            method = method.to_s
            return_type = "T.untyped"

            create_method(
              klass,
              method,
              parameters: [
                Parlour::RbiGenerator::Parameter.new("*args", type: return_type),
              ],
              return_type: return_type,
            )
          end
        end
      end
    end
  end
end
