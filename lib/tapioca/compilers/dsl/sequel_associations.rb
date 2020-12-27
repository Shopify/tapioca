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
      # `Tapioca::Compilers::Dsl::SequelAssociations` refines RBI files for subclasses of `Sequel::Model`
      # (see https://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html). This generator is only
      # responsible for defining the methods that would be created for the association that
      # are defined in the Sequel model.
      #
      # For example, with the following model class:
      #
      # ~~~rb
      # class Post < Sequel::Model
      #   many_to_one :category
      #   one_to_many :comments
      #   one_to_one :author, class_name: "User"
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
      # end
      #
      # module Post::GeneratedAssociationMethods
      #   sig { returns(T.nilable(::User)) }
      #   def author; end
      #
      #   sig { params(value: T.nilable(::User)).void }
      #   def author=(value); end
      #
      #   sig { returns(T.nilable(::Category)) }
      #   def category; end
      #
      #   sig { params(value: T.nilable(::Category)).void }
      #   def category=(value); end
      #
      #   sig { returns(T.Array(::Comment)) }
      #   def comments; end
      # end
      # ~~~
      class SequelAssociations < Base
        extend T::Sig

        sig { override.params(root: Parlour::RbiGenerator::Namespace, constant: T.class_of(Sequel::Model)).void }
        def decorate(root, constant)
          return if constant.table_name.blank?
          return if constant.name.blank?

          module_name = "#{constant}::GeneratedAssociationMethods"
          root.create_module(module_name) do |mod|
            constant.association_reflections.each do |association_name, reflection|
              if reflection.returns_array?
                populate_collection_assoc_getter_setter(mod, constant, association_name, reflection)
              else
                populate_single_assoc_getter_setter(mod, constant, association_name, reflection)
              end
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
            constant: T.class_of(Sequel::Model),
            association_name: T.any(String, Symbol),
            reflection: Sequel::Model::Associations::AssociationReflection
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
        end

        sig do
          params(
            klass: Parlour::RbiGenerator::Namespace,
            constant: T.class_of(Sequel::Model),
            association_name: T.any(String, Symbol),
            reflection: Sequel::Model::Associations::AssociationReflection
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
        end

        sig do
          params(
            constant: T.class_of(Sequel::Model),
            reflection: Sequel::Model::Associations::AssociationReflection
          ).returns(String)
        end
        def type_for(constant, reflection)
          return "T.untyped" if constant.table_name.blank?

          "::#{reflection.associated_class.name}"
        end

        sig do
          params(
            constant: T.class_of(Sequel::Model),
            reflection: Sequel::Model::Associations::AssociationReflection
          ).returns(String)
        end
        def relation_type_for(constant, reflection)
          "T::Array[#{reflection.associated_class.name}]"
        end
      end
    end
  end
end
