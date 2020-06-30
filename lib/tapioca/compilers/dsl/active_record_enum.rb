# typed: strict
# frozen_string_literal: true

require "parlour"

begin
  require "active_record"
rescue LoadError
  # means ActiveRecord is not installed,
  # so let's not even define the generator.
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::Dsl::ActiveRecordEnum` decorates RBI files for subclasses of
      # `ActiveRecord::Base` which declare `enum` fields
      # (see https://api.rubyonrails.org/classes/ActiveRecord/Enum.html).
      #
      # For example, with the following `ActiveRecord::Base` subclass:
      #
      # ~~~rb
      # class Post < ApplicationRecord
      #   enum title_type: %i(book all web), _suffix: :title
      # end
      # ~~~
      #
      # this generator will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   sig { void }
      #   def all_title!; end
      #
      #   sig { returns(T::Boolean) }
      #   def all_title?; end
      #
      #   sig { returns(T::Hash[T.any(String, Symbol), Integer]) }
      #   def self.title_types; end
      #
      #   sig { void }
      #   def book_title!; end
      #
      #   sig { returns(T::Boolean) }
      #   def book_title?; end
      #
      #   sig { void }
      #   def web_title!; end
      #
      #   sig { returns(T::Boolean) }
      #   def web_title?; end
      # end
      # ~~~
      class ActiveRecordEnum < Base
        extend T::Sig

        sig { override.params(root: Parlour::RbiGenerator::Namespace, constant: T.class_of(::ActiveRecord::Base)).void }
        def decorate(root, constant)
          return if constant.defined_enums.empty?

          module_name = "#{constant}::EnumMethodsModule"
          root.create_module(module_name) do |mod|
            generate_instance_methods(constant, mod)
          end

          root.path(constant) do |k|
            k.create_include(module_name)

            constant.defined_enums.each do |name, enum_map|
              type = type_for_enum(enum_map)
              create_method(k, name.pluralize, class_method: true, return_type: type)
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          ::ActiveRecord::Base.descendants.reject(&:abstract_class?)
        end

        private

        sig { params(enum_map: T::Hash[T.untyped, T.untyped]).returns(String) }
        def type_for_enum(enum_map)
          value_type = enum_map.values.map { |v| v.class.name }.uniq
          value_type = if value_type.length == 1
            value_type.first
          else
            "T.any(#{value_type.join(', ')})"
          end

          "T::Hash[T.any(String, Symbol), #{value_type}]"
        end

        sig { params(constant: T.class_of(::ActiveRecord::Base), klass: Parlour::RbiGenerator::Namespace).void }
        def generate_instance_methods(constant, klass)
          methods = constant.send(:_enum_methods_module).instance_methods

          methods.each do |method|
            method = method.to_s
            return_type = "T::Boolean" if method.end_with?("?")

            create_method(klass, method, return_type: return_type)
          end
        end
      end
    end
  end
end
