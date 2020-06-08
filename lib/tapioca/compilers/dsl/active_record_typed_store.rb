# typed: true
# frozen_string_literal: true

require "parlour"
require "tapioca/core_ext/class"

begin
  require "activerecord-typedstore"
rescue LoadError
  # means ActiveRecord::TypedStore is not installed,
  # so let's not even define the generator.
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::DSL::ActiveRecordTypedStore` generates RBI files for ActiveRecord models that use
      # `ActiveRecord::TypedStore` features (see https://github.com/byroot/activerecord-typedstore).
      #
      # For example, with the following ActiveRecord class:
      #
      # ~~~rb
      # # post.rb
      # class Post < ApplicationRecord
      #   typed_store :metadata do |s|
      #     s.string(:reviewer, blank: false, accessor: false)
      #     s.date(:review_date)
      #     s.boolean(:reviewed, null: false, default: false)
      #   end
      # end
      # ~~~
      #
      # this generator will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   sig { params(review_date: T.nilable(Date)).returns(T.nilable(Date)) }
      #   def review_date=(review_date); end
      #
      #   sig { returns(T.nilable(Date)) }
      #   def review_date; end
      #
      #   sig { returns(T.nilable(Date)) }
      #   def review_date_was; end
      #
      #   sig { returns(T::Boolean) }
      #   def review_date_changed?; end
      #
      #   sig { returns(T.nilable(Date)) }
      #   def review_date_before_last_save; end
      #
      #   sig { returns(T::Boolean) }
      #   def saved_change_to_review_date?; end
      #
      #   sig { returns(T.nilable([T.nilable(Date), T.nilable(Date)])) }
      #   def review_date_change; end
      #
      #   sig { returns(T.nilable([T.nilable(Date), T.nilable(Date)])) }
      #   def saved_change_to_review_date; end
      #
      #   sig { params(reviewd: T::Boolean).returns(T::Boolean) }
      #   def reviewed=(reviewed); end
      #
      #   sig { returns(T::Boolean) }
      #   def reviewed; end
      #
      #   sig { returns(T::Boolean) }
      #   def reviewed_was; end
      #
      #   sig { returns(T::Boolean) }
      #   def reviewed_changed?; end
      #
      #   sig { returns(T::Boolean) }
      #   def reviewed_before_last_save; end
      #
      #   sig { returns(T::Boolean) }
      #   def saved_change_to_reviewed?; end
      #
      #   sig { returns(T.nilable([T::Boolean, T::Boolean])) }
      #   def reviewed_change; end
      #
      #   sig { returns(T.nilable([T::Boolean, T::Boolean])) }
      #   def saved_change_to_reviewed; end
      # end
      # ~~~
      # end

      class ActiveRecordTypedStore < Base
        extend T::Sig

        sig do
          override
            .params(
              root: Parlour::RbiGenerator::Namespace,
              constant: T.class_of(::ActiveRecord::Base)
            )
            .void
        end
        def decorate(root, constant)
          stores = constant.typed_stores
          return if stores.values.flat_map(&:accessors).empty?

          root.path(constant) do |k|
            stores.values.each do |store_data|
              store_data.accessors.each do |accessor|
                field = store_data.fields[accessor]
                type = type_for(field.type_sym)
                type = "T.nilable(#{type})" if field.null && type != "T.untyped"
                generate_methods(field.name.to_s, type, k)
              end
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          ::ActiveRecord::Base.descendants.select do |klass|
            klass.include?(ActiveRecord::TypedStore::Behavior)
          end
        end

        private

        TYPES =
          {
            boolean: "T::Boolean",
            integer: "Integer",
            string: "String",
            float: "Float",
            date: "Date",
            time: "Time",
            datetime: "DateTime",
            decimal: "BigDecimal",
            any: "T.untyped",
          }
        def type_for(attr_type)
          TYPES.fetch(attr_type, "T.untyped")
        end

        sig do
          params(
            name: String,
            type: String,
            klass: Parlour::RbiGenerator::Namespace
          )
            .void
        end
        def generate_methods(name, type, klass)
          klass.create_method(
            "#{name}=",
            parameters: [Parlour::RbiGenerator::Parameter.new(name, type: type)],
            return_type: type
          )
          klass.create_method(name, return_type: type)
          klass.create_method("#{name}?", return_type: "T::Boolean")
          klass.create_method("#{name}_was", return_type: type)
          klass.create_method("#{name}_changed?", return_type: "T::Boolean")
          klass.create_method("#{name}_before_last_save", return_type: type)
          klass.create_method("saved_change_to_#{name}?", return_type: "T::Boolean")
          klass.create_method("#{name}_change", return_type: "T.nilable([#{type}, #{type}])")
          klass.create_method("saved_change_to_#{name}", return_type: "T.nilable([#{type}, #{type}])")
        end
      end
    end
  end
end
