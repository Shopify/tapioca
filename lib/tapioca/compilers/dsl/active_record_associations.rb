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
      # `Tapioca::Compilers::Dsl::ActiveRecordAssociations` refines RBI files for subclasses of
      # [`ActiveRecord::Base`](https://api.rubyonrails.org/classes/ActiveRecord/Base.html).
      # This generator is only responsible for defining the methods that would be created for the associations that
      # are defined in the Active Record model.
      #
      # For example, with the following model class:
      #
      # ~~~rb
      # class Post < ActiveRecord::Base
      #   belongs_to :category
      #   has_many :comments
      #   has_one :author, class_name: "User"
      #
      #   accepts_nested_attributes_for :category, :comments, :author
      # end
      # ~~~
      #
      # this generator will produce the following methods in the RBI file
      # `post.rbi`:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      #
      # class Post
      #   include Post::GeneratedAssociationMethods
      #
      #   module Post::GeneratedAssociationMethods
      #     sig { returns(T.nilable(::User)) }
      #     def author; end
      #
      #     sig { params(value: T.nilable(::User)).void }
      #     def author=(value); end
      #
      #     sig { params(attributes: T.untyped).returns(T.untyped) }
      #     def author_attributes=(attributes); end
      #
      #     sig { params(args: T.untyped, blk: T.untyped).returns(::User) }
      #     def build_author(*args, &blk); end
      #
      #     sig { params(args: T.untyped, blk: T.untyped).returns(::Category) }
      #     def build_category(*args, &blk); end
      #
      #     sig { returns(T.nilable(::Category)) }
      #     def category; end
      #
      #     sig { params(value: T.nilable(::Category)).void }
      #     def category=(value); end
      #
      #     sig { params(attributes: T.untyped).returns(T.untyped) }
      #     def category_attributes=(attributes); end
      #
      #     sig { returns(T::Array[T.untyped]) }
      #     def comment_ids; end
      #
      #     sig { params(ids: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
      #     def comment_ids=(ids); end
      #
      #     sig { returns(::ActiveRecord::Associations::CollectionProxy[Comment]) }
      #     def comments; end
      #
      #     sig { params(value: T::Enumerable[::Comment]).void }
      #     def comments=(value); end
      #
      #     sig { params(attributes: T.untyped).returns(T.untyped) }
      #     def comments_attributes=(attributes); end
      #
      #     sig { params(args: T.untyped, blk: T.untyped).returns(::User) }
      #     def create_author(*args, &blk); end
      #
      #     sig { params(args: T.untyped, blk: T.untyped).returns(::User) }
      #     def create_author!(*args, &blk); end
      #
      #     sig { params(args: T.untyped, blk: T.untyped).returns(::Category) }
      #     def create_category(*args, &blk); end
      #
      #     sig { params(args: T.untyped, blk: T.untyped).returns(::Category) }
      #     def create_category!(*args, &blk); end
      #
      #     sig { returns(T.nilable(::User)) }
      #     def reload_author; end
      #
      #     sig { returns(T.nilable(::Category)) }
      #     def reload_category; end
      #   end
      # end
      # ~~~
      class ActiveRecordAssociations < Base
        extend T::Sig

        ReflectionType = T.type_alias do
          T.any(::ActiveRecord::Reflection::ThroughReflection, ::ActiveRecord::Reflection::AssociationReflection)
        end

        sig { override.params(root: Parlour::RbiGenerator::Namespace, constant: T.class_of(ActiveRecord::Base)).void }
        def decorate(root, constant)
          return if constant.reflections.empty?

          root.path(constant) do |model|
            module_name = "GeneratedAssociationMethods"

            model.create_module(module_name) do |mod|
              populate_nested_attribute_writers(mod, constant)
              populate_associations(mod, constant)
            end

            model.create_include(module_name)
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          ActiveRecord::Base.descendants.reject(&:abstract_class?)
        end

        private

        sig { params(mod: Parlour::RbiGenerator::Namespace, constant: T.class_of(ActiveRecord::Base)).void }
        def populate_nested_attribute_writers(mod, constant)
          constant.nested_attributes_options.keys.each do |association_name|
            create_method(
              mod,
              "#{association_name}_attributes=",
              parameters: [
                Parlour::RbiGenerator::Parameter.new("attributes", type: "T.untyped"),
              ],
              return_type: "T.untyped"
            )
          end
        end

        sig { params(mod: Parlour::RbiGenerator::Namespace, constant: T.class_of(ActiveRecord::Base)).void }
        def populate_associations(mod, constant)
          constant.reflections.each do |association_name, reflection|
            if reflection.collection?
              populate_collection_assoc_getter_setter(mod, constant, association_name, reflection)
            else
              populate_single_assoc_getter_setter(mod, constant, association_name, reflection)
            end
          end
        end

        sig do
          params(
            klass: Parlour::RbiGenerator::Namespace,
            constant: T.class_of(ActiveRecord::Base),
            association_name: T.any(String, Symbol),
            reflection: ReflectionType
          ).void
        end
        def populate_single_assoc_getter_setter(klass, constant, association_name, reflection)
          association_class = type_for(constant, reflection)
          association_type = "T.nilable(#{association_class})"

          create_method(
            klass,
            association_name.to_s,
            return_type: association_type,
          )
          create_method(
            klass,
            "#{association_name}=",
            parameters: [
              Parlour::RbiGenerator::Parameter.new("value", type: association_type),
            ],
            return_type: nil
          )
          create_method(
            klass,
            "reload_#{association_name}",
            return_type: association_type,
          )
          unless reflection.polymorphic?
            create_method(
              klass,
              "build_#{association_name}",
              parameters: [
                Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped"),
                Parlour::RbiGenerator::Parameter.new("&blk", type: "T.untyped"),
              ],
              return_type: association_class
            )
            create_method(
              klass,
              "create_#{association_name}",
              parameters: [
                Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped"),
                Parlour::RbiGenerator::Parameter.new("&blk", type: "T.untyped"),
              ],
              return_type: association_class
            )
            create_method(
              klass,
              "create_#{association_name}!",
              parameters: [
                Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped"),
                Parlour::RbiGenerator::Parameter.new("&blk", type: "T.untyped"),
              ],
              return_type: association_class
            )
          end
        end

        sig do
          params(
            klass: Parlour::RbiGenerator::Namespace,
            constant: T.class_of(ActiveRecord::Base),
            association_name: T.any(String, Symbol),
            reflection: ReflectionType
          ).void
        end
        def populate_collection_assoc_getter_setter(klass, constant, association_name, reflection)
          association_class = type_for(constant, reflection)
          relation_class = relation_type_for(constant, reflection)

          create_method(
            klass,
            association_name.to_s,
            return_type: relation_class,
          )
          create_method(
            klass,
            "#{association_name}=",
            parameters: [
              Parlour::RbiGenerator::Parameter.new("value", type: "T::Enumerable[#{association_class}]"),
            ],
            return_type: nil,
          )
          create_method(
            klass,
            "#{association_name.to_s.singularize}_ids",
            return_type: "T::Array[T.untyped]"
          )
          create_method(
            klass,
            "#{association_name.to_s.singularize}_ids=",
            parameters: [
              Parlour::RbiGenerator::Parameter.new("ids", type: "T::Array[T.untyped]"),
            ],
            return_type: "T::Array[T.untyped]"
          )
        end

        sig do
          params(
            constant: T.class_of(ActiveRecord::Base),
            reflection: ReflectionType
          ).returns(String)
        end
        def type_for(constant, reflection)
          return "T.untyped" if !constant.table_exists? || polymorphic_association?(reflection)

          "::#{reflection.klass.name}"
        end

        sig do
          params(
            constant: T.class_of(ActiveRecord::Base),
            reflection: ReflectionType
          ).returns(String)
        end
        def relation_type_for(constant, reflection)
          "ActiveRecord::Associations::CollectionProxy" if !constant.table_exists? ||
                                                            polymorphic_association?(reflection)

          # Change to: "::#{reflection.klass.name}::ActiveRecord_Associations_CollectionProxy"
          "::ActiveRecord::Associations::CollectionProxy[#{reflection.klass.name}]"
        end

        sig do
          params(
            reflection: ReflectionType
          ).returns(T::Boolean)
        end
        def polymorphic_association?(reflection)
          if reflection.through_reflection?
            polymorphic_association?(reflection.source_reflection)
          else
            !!reflection.polymorphic?
          end
        end
      end
    end
  end
end
