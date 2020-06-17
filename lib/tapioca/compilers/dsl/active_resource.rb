# typed: true
# frozen_string_literal: true

require "parlour"

begin
  require "active_record"
  require "active_resource"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::Dsl::ActiveResource` decorates RBI files for subclasses of
      # `ActiveResource::Base` which declare `schema` fields
      # (see https://api.rubyonrails.org/v3.2.6/classes/ActiveResource/Base.html).
      #
      # For example, with the following `ActiveResource::Base` subclass:
      #
      # ~~~rb
      # class Post < ActiveResource::Base
      #   schema do
      #     integer 'id', 'month', 'year'
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
      #   sig { returns(Integer) }
      #   def id; end
      #
      #   sig { params(id: Integer).returns(Integer) }
      #   def id=(id); end
      #
      #   sig { returns(T::Boolean) }
      #   def id?; end
      #
      #   sig { returns(Integer) }
      #   def month; end
      #
      #   sig { params(month: Integer).returns(Integer) }
      #   def month=(month); end
      #
      #   sig { returns(T::Boolean) }
      #   def month?; end
      #
      #   sig { returns(Integer) }
      #   def year; end
      #
      #   sig { params(year: Integer).returns(Integer) }
      #   def year=(year); end
      #
      #   sig { returns(T::Boolean) }
      #   def year?; end
      # end
      # ~~~
      class ActiveResource < Base
        extend T::Sig

        sig do
          override.params(
            root: Parlour::RbiGenerator::Namespace,
            constant: T.class_of(::ActiveResource::Base)
          ).void
        end
        def decorate(root, constant)
          return if constant.schema.blank?
          root.path(constant) do |k|
            constant.schema.each do |schema, type|
              create_schema_methods(k, schema, type)
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          ::ActiveResource::Base.descendants
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
            k: Parlour::RbiGenerator::Namespace,
            schema: String,
            type: String
          ).void
        end
        def create_schema_methods(k, schema, type)
          return_type = type_for(type.to_sym)
          k.create_method(schema,
            return_type: return_type)

          k.create_method("#{schema}?",
            return_type: "T::Boolean")

          k.create_method("#{schema}=", parameters: [
            Parlour::RbiGenerator::Parameter.new(schema, type: return_type),
          ], return_type: return_type)
        end
      end
    end
  end
end
