# typed: strict
# frozen_string_literal: true

require "parlour"

begin
  require "rails/railtie"
  require "identity_cache"
rescue LoadError
  # means IdentityCache is not installed,
  # so let's not even define the generator.
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::DSL::ActiveRecordIdentityCache` generates RBI files for ActiveRecord models
      #  that use `include IdentityCache`.
      # `IdentityCache` is a blob level caching solution to plug into ActiveRecord. (see https://github.com/Shopify/identity_cache).
      #
      # For example, with the following ActiveRecord class:
      #
      # ~~~rb
      # # post.rb
      # class Post < ApplicationRecord
      #    include IdentityCache
      #
      #    cache_index :blog_id
      #    cache_index :title, unique: true
      #    cache_index :title, :review_date, unique: true
      #
      # end
      # ~~~
      #
      # this generator will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   sig { params(blog_id: T.untyped, includes: T.untyped).returns(T::Array[::Post])
      #   def fetch_by_blog_id(blog_id, includes: nil); end
      #
      #   sig { params(blog_ids: T.untyped, includes: T.untyped).returns(T::Array[::Post])
      #   def fetch_multi_by_blog_id(index_values, includes: nil); end
      #
      #   sig { params(title: T.untyped, includes: T.untyped).returns(::Post) }
      #   def fetch_by_title!(title, includes: nil); end
      #
      #   sig { params(title: T.untyped, includes: T.untyped).returns(T.nilable(::Post)) }
      #   def fetch_by_title(title, includes: nil); end
      #
      #   sig { params(index_values: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
      #   def fetch_multi_by_title(index_values, includes: nil); end
      #
      #   sig { params(title: T.untyped, review_date: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
      #   def fetch_by_title_and_review_date!(title, review_date, includes: nil); end
      #
      #   sig { params(title: T.untyped, review_date: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
      #   def fetch_by_title_and_review_date(title, review_date, includes: nil); end
      # end
      # ~~~
      class ActiveRecordIdentityCache < Base
        extend T::Sig

        COLLECTION_TYPE = T.let(
          ->(type) { "T::Array[::#{type}]" },
          T.proc.params(type: Module).returns(String)
        )

        sig do
          override
            .params(
              root: Parlour::RbiGenerator::Namespace,
              constant: T.class_of(::ActiveRecord::Base)
            )
            .void
        end
        def decorate(root, constant)
          caches = constant.send(:all_cached_associations)
          cache_indexes = constant.send(:cache_indexes)
          return if caches.empty? && cache_indexes.empty?

          root.path(constant) do |k|
            cache_manys = constant.send(:cached_has_manys)
            cache_ones = constant.send(:cached_has_ones)
            cache_belongs = constant.send(:cached_belongs_tos)

            cache_indexes.each do |field|
              create_fetch_by_methods(field, k, constant)
            end

            cache_manys.values.each do |field|
              create_fetch_field_methods(field, k, returns_collection: true)
            end

            cache_ones.values.each do |field|
              create_fetch_field_methods(field, k, returns_collection: false)
            end

            cache_belongs.values.each do |field|
              create_fetch_field_methods(field, k, returns_collection: false)
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          ::ActiveRecord::Base.descendants.select do |klass|
            klass < IdentityCache
          end
        end

        private

        sig do
          params(
            field: T.untyped,
            returns_collection: T::Boolean
          )
            .returns(String)
        end
        def type_for_field(field, returns_collection:)
          cache_type = field.reflection.compute_class(field.reflection.class_name)
          if returns_collection
            COLLECTION_TYPE.call(cache_type)
          else
            "T.nilable(::#{cache_type})"
          end
        rescue ArgumentError
          "T.untyped"
        end

        sig do
          params(
            field: T.untyped,
            klass: Parlour::RbiGenerator::Namespace,
            returns_collection: T::Boolean
          )
            .void
        end
        def create_fetch_field_methods(field, klass, returns_collection:)
          name = field.cached_accessor_name.to_s
          type = type_for_field(field, returns_collection: returns_collection)
          klass.create_method(name, return_type: type)

          if field.respond_to?(:cached_ids_name)
            klass.create_method(field.cached_ids_name, return_type: "T::Array[T.untyped]")
          elsif field.respond_to?(:cached_id_name)
            klass.create_method(field.cached_id_name, return_type: "T.untyped")
          end
        end

        sig do
          params(
            field: T.untyped,
            klass: Parlour::RbiGenerator::Namespace,
            constant: T.class_of(::ActiveRecord::Base),
          )
            .void
        end
        def create_fetch_by_methods(field, klass, constant)
          field_length = field.key_fields.length
          fields_name = field.key_fields.join("_and_")

          parameters = field.key_fields.map do |arg|
            Parlour::RbiGenerator::Parameter.new(arg.to_s, type: "T.untyped")
          end
          parameters << Parlour::RbiGenerator::Parameter.new("includes:", default: "nil", type: "T.untyped")

          name = "fetch_by_#{fields_name}"
          if field.unique
            klass.create_method(
              "#{name}!",
              class_method: true,
              parameters: parameters,
              return_type: "::#{constant}"
            )

            klass.create_method(
              name,
              class_method: true,
              parameters: parameters,
              return_type: "T.nilable(::#{constant})"
            )
          else
            klass.create_method(
              name,
              class_method: true,
              parameters: parameters,
              return_type: COLLECTION_TYPE.call(constant)
            )
          end

          if field_length == 1
            name = "fetch_multi_by_#{fields_name}"
            klass.create_method(
              name,
              class_method: true,
              parameters: [
                Parlour::RbiGenerator::Parameter.new("index_values", type: "T.untyped"),
                Parlour::RbiGenerator::Parameter.new("includes:", default: "nil", type: "T.untyped"),
              ],
              return_type: COLLECTION_TYPE.call(constant)
            )
          end
        end
      end
    end
  end
end
