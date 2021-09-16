# typed: strict
# frozen_string_literal: true

begin
  require "smart_properties"
rescue LoadError
  # means SmartProperties is not installed,
  # so let's not even define the generator.
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::Dsl::SmartProperties` generates RBI files for classes that include
      # [`SmartProperties`](https://github.com/t6d/smart_properties).
      #
      # For example, with the following class that includes `SmartProperties`:
      #
      # ~~~rb
      # # post.rb
      # class Post
      #   include(SmartProperties)
      #
      #   property :title, accepts: String
      #   property! :description, accepts: String
      #   property :published, accepts: [true, false], reader: :published?
      #   property :enabled, accepts: [true, false], default: false
      # end
      # ~~~
      #
      # this generator will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   sig { returns(T.nilable(::String)) }
      #   def title; end
      #
      #   sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
      #   def title=(title); end
      #
      #   sig { returns(::String) }
      #   def description; end
      #
      #   sig { params(description: ::String).returns(::String) }
      #   def description=(description); end
      #
      #   sig { returns(T.nilable(T::Boolean)) }
      #   def published?; end
      #
      #   sig { params(published: T.nilable(T::Boolean)).returns(T.nilable(T::Boolean)) }
      #   def published=(published); end
      #
      #   sig { returns(T.nilable(T::Boolean)) }
      #   def enabled; end
      #
      #   sig { params(enabled: T.nilable(T::Boolean)).returns(T.nilable(T::Boolean)) }
      #   def enabled=(enabled); end
      # end
      # ~~~
      class SmartProperties < Base
        extend T::Sig

        sig { override.params(root: RBI::Tree, constant: T.class_of(::SmartProperties)).void }
        def decorate(root, constant)
          properties = T.let(
            T.unsafe(constant).properties,
            ::SmartProperties::PropertyCollection
          )
          return if properties.keys.empty?

          instance_methods = constant.instance_methods(false).map(&:to_s).to_set

          root.create_path(constant) do |k|
            properties.values.each do |property|
              generate_methods_for_property(k, property) do |method_name|
                !instance_methods.include?(method_name.to_sym)
              end
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          all_modules.select do |c|
            name_of(c) &&
              c != ::SmartProperties::Validations::Ancestor &&
              c < ::SmartProperties && ::SmartProperties::ClassMethods === c
          end
        end

        private

        sig do
          params(
            klass: RBI::Scope,
            property: ::SmartProperties::Property,
            block: T.proc.params(arg: String).returns(T::Boolean)
          ).void
        end
        def generate_methods_for_property(klass, property, &block)
          type = type_for(property)

          if property.writable?
            name = property.name.to_s
            method_name = "#{name}="

            klass.create_method(
              method_name,
              parameters: [create_param(name, type: type)],
              return_type: type
            ) if block.call(method_name)
          end

          klass.create_method(property.reader.to_s, return_type: type) if block.call(property.reader.to_s)
        end

        BOOLEANS = T.let([
          [true, false],
          [false, true],
        ].freeze, T::Array[[T::Boolean, T::Boolean]])

        sig { params(property: ::SmartProperties::Property).returns(String) }
        def type_for(property)
          converter, accepter, required = property.to_h.fetch_values(
            :converter,
            :accepter,
            :required,
          )

          return "T.untyped" if converter

          type = if accepter.nil? || accepter.respond_to?(:to_proc)
            "T.untyped"
          elsif accepter == Array
            "T::Array[T.untyped]"
          elsif BOOLEANS.include?(accepter)
            "T::Boolean"
          elsif Array(accepter).all? { |a| a.is_a?(Module) }
            accepters = Array(accepter)
            types = accepters.map { |mod| T.must(qualified_name_of(mod)) }.join(", ")
            types = "T.any(#{types})" if accepters.size > 1
            types
          else
            "T.untyped"
          end

          # Early return for "T.untyped", nothing more to do.
          return type if type == "T.untyped"

          might_be_optional = Proc === required || !required
          type = "T.nilable(#{type})" if might_be_optional

          type
        end
      end
    end
  end
end
