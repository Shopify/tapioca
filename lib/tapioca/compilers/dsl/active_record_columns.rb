# typed: strict
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
      # `Tapioca::Compilers::Dsl::ActiveRecordColumns` refines RBI files for subclasses of `ActiveRecord::Base`
      # (see https://api.rubyonrails.org/classes/ActiveRecord/Base.html). This generator is only
      # responsible for defining the attribute methods that would be created for the columns that
      # are defined in the Active Record model.
      #
      # For example, with the following model class:
      #
      # ~~~rb
      # class Post < ActiveRecord::Base
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
      #
      #   sig { returns(T.nilable(::ActiveSupport::TimeWithZone)) }
      #   def updated_at; end
      #
      #   sig { params(value: ::ActiveSupport::TimeWithZone).returns(::ActiveSupport::TimeWithZone) }
      #   def updated_at=; end
      #
      #   sig { params(args: T.untyped).returns(T::Boolean) }
      #   def updated_at?; end
      #
      #   ## Also the methods added by https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Dirty.html
      #   ## Also the methods added by https://api.rubyonrails.org/classes/ActiveModel/Dirty.html
      #   ## Also the methods added by https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/BeforeTypeCast.html
      # end
      # ~~~
      class ActiveRecordColumns < Base
        extend T::Sig

        sig { override.params(root: Parlour::RbiGenerator::Namespace, constant: T.class_of(ActiveRecord::Base)).void }
        def decorate(root, constant)
          return unless constant.table_exists?

          module_name = "#{constant}::GeneratedAttributeMethods"
          root.create_module(module_name) do |mod|
            constant.columns_hash.each_key do |column_name|
              column_name = column_name.to_s
              add_methods_for_attribute(mod, constant, column_name)
            end

            constant.attribute_aliases.each do |attribute_name, column_name|
              attribute_name = attribute_name.to_s
              column_name = column_name.to_s
              new_method_names = constant.attribute_method_matchers.map { |m| m.method_name(attribute_name) }
              old_method_names = constant.attribute_method_matchers.map { |m| m.method_name(column_name) }
              methods_to_add = new_method_names - old_method_names

              add_methods_for_attribute(mod, constant, column_name, attribute_name, methods_to_add)
            end
          end

          root.path(constant) do |klass|
            klass.create_include(module_name)
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          ActiveRecord::Base.descendants.reject(&:abstract_class?)
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
            constant: T.class_of(ActiveRecord::Base),
            column_name: String,
            attribute_name: String,
            methods_to_add: T.nilable(T::Array[String])
          ).void
        end
        def add_methods_for_attribute(klass, constant, column_name, attribute_name = column_name, methods_to_add = nil)
          getter_type, setter_type = type_for(constant, column_name)

          # Added by ActiveRecord::AttributeMethods::Read
          #
          add_method(
            klass,
            attribute_name.to_s,
            methods_to_add,
            return_type: getter_type
          )

          # Added by ActiveRecord::AttributeMethods::Write
          #
          add_method(
            klass,
            "#{attribute_name}=",
            methods_to_add,
            parameters: [["value", setter_type]],
            return_type: setter_type
          )

          # Added by ActiveRecord::AttributeMethods::Query
          #
          add_method(
            klass,
            "#{attribute_name}?",
            methods_to_add,
            return_type: "T::Boolean"
          )

          # Added by ActiveRecord::AttributeMethods::Dirty
          #
          add_method(
            klass,
            "#{attribute_name}_before_last_save",
            methods_to_add,
            return_type: getter_type
          )
          add_method(
            klass,
            "#{attribute_name}_change_to_be_saved",
            methods_to_add,
            return_type: "[#{getter_type}, #{getter_type}]"
          )
          add_method(
            klass,
            "#{attribute_name}_in_database",
            methods_to_add,
            return_type: getter_type
          )
          add_method(
            klass,
            "saved_change_to_#{attribute_name}",
            methods_to_add,
            return_type: "[#{getter_type}, #{getter_type}]"
          )
          add_method(
            klass,
            "saved_change_to_#{attribute_name}?",
            methods_to_add,
            return_type: "T::Boolean"
          )
          add_method(
            klass,
            "will_save_change_to_#{attribute_name}?",
            methods_to_add,
            return_type: "T::Boolean"
          )

          # Added by ActiveModel::Dirty
          #
          add_method(
            klass,
            "#{attribute_name}_change",
            methods_to_add,
            return_type: "[#{getter_type}, #{getter_type}]"
          )
          add_method(
            klass,
            "#{attribute_name}_changed?",
            methods_to_add,
            return_type: "T::Boolean"
          )
          add_method(
            klass,
            "#{attribute_name}_will_change!",
            methods_to_add
          )
          add_method(
            klass,
            "#{attribute_name}_was",
            methods_to_add,
            return_type: getter_type
          )
          add_method(
            klass,
            "#{attribute_name}_previous_change",
            methods_to_add,
            return_type: "[#{getter_type}, #{getter_type}]"
          )
          add_method(
            klass,
            "#{attribute_name}_previously_changed?",
            methods_to_add,
            return_type: "T::Boolean"
          )
          add_method(
            klass,
            "#{attribute_name}_previously_was",
            methods_to_add,
            return_type: getter_type
          )
          add_method(
            klass,
            "restore_#{attribute_name}!",
            methods_to_add
          )

          # Added by ActiveRecord::AttributeMethods::BeforeTypeCast
          #
          add_method(
            klass,
            "#{attribute_name}_before_type_cast",
            methods_to_add,
            return_type: "T.untyped"
          )
          add_method(
            klass,
            "#{attribute_name}_came_from_user?",
            methods_to_add,
            return_type: "T::Boolean"
          )
        end

        sig do
          params(
            constant: T.class_of(ActiveRecord::Base),
            column_name: String
          ).returns([String, String])
        end
        def type_for(constant, column_name)
          return ["T.untyped", "T.untyped"] if do_not_generate_strong_types?(constant)

          column_type = constant.attribute_types[column_name]

          getter_type =
            case column_type
            when ActiveRecord::Type::Integer
              "::Integer"
            when ActiveRecord::Type::String
              "::String"
            when ActiveRecord::Type::Date
              "::Date"
            when ActiveRecord::Type::Decimal
              "::BigDecimal"
            when ActiveRecord::Type::Float
              "::Float"
            when ActiveRecord::Type::Boolean
              "T::Boolean"
            when ActiveRecord::Type::DateTime, ActiveRecord::Type::Time
              "::DateTime"
            when ActiveRecord::AttributeMethods::TimeZoneConversion::TimeZoneConverter
              "::ActiveSupport::TimeWithZone"
            else
              handle_unknown_type(column_type)
            end

          column = constant.columns_hash[column_name]
          setter_type = getter_type

          if column&.null
            return ["T.nilable(#{getter_type})", "T.nilable(#{setter_type})"]
          end

          if column_name == constant.primary_key ||
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

        sig { params(column_type: Module).returns(String) }
        def handle_unknown_type(column_type)
          return "T.untyped" unless column_type < ActiveModel::Type::Value

          lookup_return_type_of_method(column_type, :deserialize) ||
            lookup_return_type_of_method(column_type, :cast) ||
            lookup_arg_type_of_method(column_type, :serialize) ||
            "T.untyped"
        end

        sig { params(column_type: Module, method: Symbol).returns(T.nilable(String)) }
        def lookup_return_type_of_method(column_type, method)
          signature = T::Private::Methods.signature_for_method(column_type.instance_method(method))
          return unless signature

          return_type = signature.return_type.to_s
          return_type if return_type != "<VOID>" && return_type != "<NOT-TYPED>"
        end

        sig { params(column_type: Module, method: Symbol).returns(T.nilable(String)) }
        def lookup_arg_type_of_method(column_type, method)
          signature = T::Private::Methods.signature_for_method(column_type.instance_method(method))
          signature.arg_types.first.last.to_s if signature
        end
      end
    end
  end
end
