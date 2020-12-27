# typed: strict
# frozen_string_literal: true

require "parlour"

begin
  require "sequel"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::Dsl::SequelColumns` refines RBI files for subclasses of `ActiveRecord::Base`
      # (see https://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html). This generator is only
      # responsible for defining the attribute methods that would be created for the columns that
      # are defined in the Sequel model.
      #
      # **Note:** This generator, by default, generates weak signatures for column methods and treats each
      # column to be `T.untyped`. This is done on purpose to ensure that the nilability of Sequel
      #
      # For example, with the following model class:
      #
      # ~~~rb
      # class Post < Sequel::Model
      # end
      # ~~~
      #
      # and the following database schema:
      #
      # ~~~rb
      # # db/schema.rb
      # create_table :posts do |t|
      #   t.string :title, null: false
      #   t.string :body
      #   t.boolean :published
      #   t.timestamps
      # end
      # ~~~
      #
      # this generator will produce the following methods in the RBI file
      # `post.rbi`:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   sig { returns(T.nilable(::String)) }
      #   def body; end
      #
      #   sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
      #   def body=; end
      #
      #   sig { params(args: T.untyped).returns(T::Boolean) }
      #   def body?; end
      #
      #   sig { returns(T.nilable(::ActiveSupport::TimeWithZone)) }
      #   def created_at; end
      #
      #   sig { params(value: ::ActiveSupport::TimeWithZone).returns(::ActiveSupport::TimeWithZone) }
      #   def created_at=; end
      #
      #   sig { params(args: T.untyped).returns(T::Boolean) }
      #   def created_at?; end
      #
      #   sig { returns(T.nilable(T::Boolean)) }
      #   def published; end
      #
      #   sig { params(value: T::Boolean).returns(T::Boolean) }
      #   def published=; end
      #
      #   sig { params(args: T.untyped).returns(T::Boolean) }
      #   def published?; end
      #
      #   sig { returns(::String) }
      #   def title; end
      #
      #   sig { params(value: ::String).returns(::String) }
      #   def title=(value); end
      #
      #   sig { params(args: T.untyped).returns(T::Boolean) }
      #   def title?(*args); end
      # end
      # ~~~
      class SequelColumns < Base
        extend T::Sig

        sig { override.params(root: Parlour::RbiGenerator::Namespace, constant: T.class_of(Sequel::Model)).void }
        def decorate(root, constant)
          return if constant.table_name.blank?
          return if constant.name.blank?

          module_name = "#{constant}::GeneratedAttributeMethods"
          root.create_module(module_name) do |mod|
            constant.columns.each do |column_name|
              column_name = column_name.to_s
              add_methods_for_attribute(mod, constant, column_name)
            end
          end

          root.path(constant) do |klass|
            klass.create_include(module_name)
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          Sequel::Model.descendants
        end

        private

        sig do
          params(
            klass: Parlour::RbiGenerator::Namespace,
            name: String,
            methods_to_add: T.nilable(T::Array[String]),
            return_type: T.nilable(String),
            parameters: T::Array[[String, String]]
          ).void
        end
        def add_method(klass, name, methods_to_add, return_type: nil, parameters: [])
          create_method(
            klass,
            name,
            parameters: parameters.map do |param, type|
              Parlour::RbiGenerator::Parameter.new(param, type: type)
            end,
            return_type: return_type
          ) if methods_to_add.nil? || methods_to_add.include?(name)
        end

        sig do
          params(
            klass: Parlour::RbiGenerator::Namespace,
            constant: T.class_of(Sequel::Model),
            column_name: String,
            attribute_name: String,
            methods_to_add: T.nilable(T::Array[String])
          ).void
        end
        def add_methods_for_attribute(klass, constant, column_name, attribute_name = column_name, methods_to_add = nil)
          getter_type, setter_type = type_for(constant, column_name)

          add_method(
            klass,
            attribute_name.to_s,
            methods_to_add,
            return_type: getter_type
          )

          add_method(
            klass,
            "#{attribute_name}=",
            methods_to_add,
            parameters: [["value", setter_type]],
            return_type: setter_type
          )
        end

        sig do
          params(
            constant: T.class_of(Sequel::Model),
            column_name: String
          ).returns([String, String])
        end
        def type_for(constant, column_name)
          return ["T.untyped", "T.untyped"] if do_not_generate_strong_types?(constant)

          raw_column_type = constant.db_schema.dig(column_name.to_sym, :db_type)
          column_type = raw_column_type == "uuid" ? :string : constant.db.send(:schema_column_type, raw_column_type)

          getter_type =
            case column_type
            when :string
              "::String"
            when :integer
              "::Integer"
            when :date
              "::Date"
            when :datetime, :time
              "::DateTime"
            when :boolean
              "T::Boolean"
            when :float
              "::Float"
            when :decimal
              "::BigDecimal"
            else
              "T.untyped"
            end

          setter_type = getter_type

          if column_name == constant.primary_key.to_s ||
              column_name == "created_at" ||
              column_name == "updated_at"
            getter_type = "T.nilable(#{getter_type})"
          end

          [getter_type, setter_type]
        end

        sig { params(constant: Module).returns(T::Boolean) }
        def do_not_generate_strong_types?(constant)
          Object.const_defined?(:StrongTypeGeneration) &&
              !(constant.singleton_class < Object.const_get(:StrongTypeGeneration))
        end
      end
    end
  end
end
