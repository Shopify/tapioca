# typed: strict
# frozen_string_literal: true

begin
  require "smart_properties"
rescue LoadError
  # means SmartProperties is not installed,
  # so let's not even define the compiler.
  return
end

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::SmartProperties` generates RBI files for classes that include
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
      # this compiler will produce the RBI file `post.rbi` with the following content:
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
      class SmartProperties < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.all(::SmartProperties::ClassMethods, T.class_of(::SmartProperties)) } }

        sig { override.void }
        def decorate
          properties = T.let(constant.properties, ::SmartProperties::PropertyCollection)
          return if properties.keys.empty?

          root.create_path(constant) do |k|
            smart_properties_methods_name = "SmartPropertiesGeneratedMethods"
            k.create_module(smart_properties_methods_name) do |mod|
              properties.values.each do |property|
                generate_methods_for_property(mod, property)
              end
            end

            k.create_include(smart_properties_methods_name)
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_modules.select do |c|
              name_of(c) &&
                c != ::SmartProperties::Validations::Ancestor &&
                c < ::SmartProperties && ::SmartProperties::ClassMethods === c
            end
          end
        end

        private

        sig do
          params(
            mod: RBI::Scope,
            property: ::SmartProperties::Property,
          ).void
        end
        def generate_methods_for_property(mod, property)
          type = type_for(property)

          if property.writable?
            name = property.name.to_s
            method_name = "#{name}="

            mod.create_method(
              method_name,
              parameters: [create_param(name, type: type)],
              return_type: type,
            )
          end

          mod.create_method(property.reader.to_s, return_type: type)
        end

        BOOLEANS = T.let(
          [
            [true, false],
            [false, true],
          ].freeze,
          T::Array[[T::Boolean, T::Boolean]],
        )

        sig { params(property: ::SmartProperties::Property).returns(RBI::Type) }
        def type_for(property)
          converter, accepter, required = property.to_h.fetch_values(
            :converter,
            :accepter,
            :required,
          )

          return RBI::Type.untyped if converter

          type = if accepter.nil? || accepter.respond_to?(:to_proc)
            RBI::Type.untyped
          elsif accepter == Array
            RBI::Type.generic("T::Array", RBI::Type.untyped)
          elsif BOOLEANS.include?(accepter)
            RBI::Type.boolean
          elsif Array(accepter).all? { |a| a.is_a?(Module) }
            accepters = Array(accepter)
            RBI::Type.any(accepters.map { |mod| RBI::Type.simple(T.must(qualified_name_of(mod))) })
          else
            RBI::Type.untyped
          end

          might_be_optional = Proc === required || !required
          type = type.nilable if might_be_optional

          type
        end
      end
    end
  end
end
