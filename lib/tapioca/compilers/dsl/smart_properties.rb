# typed: strict
# frozen_string_literal: true

require "parlour"

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
      #   sig { returns(T::Boolean) }
      #   def enabled; end
      #
      #   sig { params(enabled: T::Boolean).returns(T::Boolean) }
      #   def enabled=(enabled); end
      # end
      # ~~~
      class SmartProperties < Base
        extend T::Sig

        sig do
          override
            .params(
              root: Parlour::RbiGenerator::Namespace,
              constant: T.class_of(::SmartProperties)
            )
            .void
        end
        def decorate(root, constant)
          properties = T.let(
            T.unsafe(constant).properties,
            ::SmartProperties::PropertyCollection
          )
          return if properties.keys.empty?

          instance_methods = constant.instance_methods(false).map(&:to_s).to_set

          root.path(constant) do |k|
            properties.values.each do |property|
              generate_methods_for_property(k, property) do |method_name|
                !instance_methods.include?(method_name.to_sym)
              end
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          classes = T.cast(ObjectSpace.each_object(Class), T::Enumerable[Class])
          classes.select do |c|
            c < ::SmartProperties
          end.reject do |c|
            c.name.nil? || c == ::SmartProperties::Validations::Ancestor
          end
        end

        private

        sig do
          params(
            klass: Parlour::RbiGenerator::Namespace,
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
              parameters: [Parlour::RbiGenerator::Parameter.new(name, type: type)],
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
          converter, accepter, default, required = property.to_h.fetch_values(
            :converter,
            :accepter,
            :default,
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
            types = accepters.map { |mod| name_of(mod) }.join(', ')
            types = "T.any(#{types})" if accepters.size > 1
            types
          else
            "T.untyped"
          end

          not_required = Proc === required || !required
          nilable_default = Proc === default || default.nil?
          property_nilable = type != "T.untyped" && not_required && nilable_default
          type = "T.nilable(#{type})" if property_nilable

          type
        end

        sig { params(type: Module).returns(String) }
        def name_of(type)
          name = Module.instance_method(:name).bind(type).call
          name.start_with?("::") ? name : "::#{name}"
        end
      end
    end
  end
end
