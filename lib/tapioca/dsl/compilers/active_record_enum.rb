# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveRecord::Base)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveRecordEnum` decorates RBI files for subclasses of
      # `ActiveRecord::Base` which declare [`enum` fields](https://api.rubyonrails.org/classes/ActiveRecord/Enum.html).
      #
      # For example, with the following `ActiveRecord::Base` subclass:
      #
      # ~~~rb
      # class Post < ApplicationRecord
      #   enum :title_type, %i(book all web), suffix: :title
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   include EnumMethodsModule
      #
      #   module EnumMethodsModule
      #     sig { void }
      #     def all_title!; end
      #
      #     sig { returns(T::Boolean) }
      #     def all_title?; end
      #
      #     sig { returns(T::Hash[T.any(String, Symbol), Integer]) }
      #     def self.title_types; end
      #
      #     sig { void }
      #     def book_title!; end
      #
      #     sig { returns(T::Boolean) }
      #     def book_title?; end
      #
      #     sig { void }
      #     def web_title!; end
      #
      #     sig { returns(T::Boolean) }
      #     def web_title?; end
      #   end
      # end
      # ~~~
      #: [ConstantType = singleton(::ActiveRecord::Base)]
      class ActiveRecordEnum < Compiler
        # @override
        #: -> void
        def decorate
          return if constant.defined_enums.empty?

          root.create_path(constant) do |model|
            module_name = "EnumMethodsModule"

            model.create_module(module_name) do |mod|
              generate_instance_methods(mod)
            end

            model.create_include(module_name)

            constant.defined_enums.each do |name, enum_map|
              type = type_for_enum(enum_map)
              model.create_method(name.pluralize, class_method: true, return_type: type)
            end
          end
        end

        class << self
          # @override
          #: -> T::Enumerable[Module]
          def gather_constants
            descendants_of(::ActiveRecord::Base)
          end
        end

        private

        #: (Hash[untyped, untyped] enum_map) -> String
        def type_for_enum(enum_map)
          value_type = enum_map.values.map { |v| v.class.name }.uniq
          value_type = if value_type.length == 1
            value_type.first
          else
            "T.any(#{value_type.join(", ")})"
          end

          "T::Hash[T.any(String, Symbol), #{value_type}]"
        end

        #: (RBI::Scope klass) -> void
        def generate_instance_methods(klass)
          methods = constant.send(:_enum_methods_module).instance_methods

          methods.each do |method|
            method = method.to_s
            return_type = method.end_with?("?") ? "T::Boolean" : "void"

            klass.create_method(method, return_type: return_type)
          end
        end
      end
    end
  end
end
