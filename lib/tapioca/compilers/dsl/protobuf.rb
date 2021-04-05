# typed: strict
# frozen_string_literal: true
require "parlour"

begin
  require "google/protobuf"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::Dsl::Protobuf` decorates RBI files for subclasses of
      # [`Google::Protobuf::MessageExts`](https://github.com/protocolbuffers/protobuf/tree/master/ruby).
      #
      # For example, with the following "cart.rb" file:
      #
      # ~~~rb
      # Google::Protobuf::DescriptorPool.generated_pool.build do
      #   add_file("cart.proto", :syntax => :proto3) do
      #     add_message "MyCart" do
      #       optional :shop_id, :int32, 1
      #       optional :customer_id, :int64, 2
      #       optional :number_value, :double, 3
      #       optional :string_value, :string, 4
      #     end
      #   end
      # end
      # ~~~
      #
      # this generator will produce the RBI file `cart.rbi` with the following content:
      #
      # ~~~rbi
      # # cart.rbi
      # # typed: strong
      # class Cart
      #   sig { returns(Integer) }
      #   def customer_id; end
      #
      #   sig { params(month: Integer).returns(Integer) }
      #   def customer_id=(value); end
      #
      #   sig { returns(Integer) }
      #   def shop_id; end
      #
      #   sig { params(value: Integer).returns(Integer) }
      #   def shop_id=(value); end
      #
      #   sig { returns(String) }
      #   def string_value; end
      #
      #   sig { params(value: String).returns(String) }
      #   def string_value=(value); end
      #
      #
      #   sig { returns(Float) }
      #   def number_value; end
      #
      #   sig { params(value: Float).returns(Float) }
      #   def number_value=(value); end
      # end
      # ~~~
      class Protobuf < Base
        # Parlour doesn't support type members out of the box, so adding the
        # ability to do that here. This should be upstreamed.
        class TypeMember < Parlour::RbiGenerator::RbiObject
          extend T::Sig

          sig { params(other: Object).returns(T::Boolean) }
          def ==(other)
            TypeMember === other && name == other.name
          end

          sig do
            override
              .params(indent_level: Integer, options: Parlour::RbiGenerator::Options)
              .returns(T::Array[String])
          end
          def generate_rbi(indent_level, options)
            [options.indented(indent_level, "#{name} = type_member")]
          end

          sig do
            override
              .params(others: T::Array[Parlour::RbiGenerator::RbiObject])
              .returns(T::Boolean)
          end
          def mergeable?(others)
            others.all? { |other| self == other }
          end

          sig { override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).void }
          def merge_into_self(others); end

          sig { override.returns(String) }
          def describe
            "Type Member (#{name})"
          end
        end

        class Field < T::Struct
          prop :name, String
          prop :type, String
          prop :init_type, String
          prop :default, String

          extend T::Sig

          sig { returns(Parlour::RbiGenerator::Parameter) }
          def to_init
            Parlour::RbiGenerator::Parameter.new("#{name}:", type: init_type, default: default)
          end
        end

        extend T::Sig

        sig do
          override.params(
            root: Parlour::RbiGenerator::Namespace,
            constant: Module
          ).void
        end
        def decorate(root, constant)
          root.path(constant) do |klass|
            if constant == Google::Protobuf::RepeatedField
              create_type_members(klass, "Elem")
            elsif constant == Google::Protobuf::Map
              create_type_members(klass, "Key", "Value")
            else
              descriptor = T.let(T.unsafe(constant).descriptor, Google::Protobuf::Descriptor)
              fields = descriptor.map { |desc| create_descriptor_method(klass, desc) }
              fields.sort_by!(&:name)

              create_method(klass, "initialize", parameters: fields.map!(&:to_init))
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          marker = Google::Protobuf::MessageExts::ClassMethods
          results = T.cast(ObjectSpace.each_object(marker).to_a, T::Array[Module])
          results.any? ? results + [Google::Protobuf::RepeatedField, Google::Protobuf::Map] : []
        end

        private

        sig { params(klass: Parlour::RbiGenerator::Namespace, names: String).void }
        def create_type_members(klass, *names)
          klass.create_extend("T::Generic")

          names.each do |name|
            klass.children << TypeMember.new(klass.generator, name)
          end
        end

        sig do
          params(
            descriptor: Google::Protobuf::FieldDescriptor
          ).returns(String)
        end
        def type_of(descriptor)
          case descriptor.type
          when :enum
            descriptor.subtype.enummodule.name
          when :message
            descriptor.subtype.msgclass.name
          when :int32, :int64, :uint32, :uint64
            "Integer"
          when :double, :float
            "Float"
          when :bool
            "T::Boolean"
          when :string, :bytes
            "String"
          else
            "T.untyped"
          end
        end

        sig { params(descriptor: Google::Protobuf::FieldDescriptor).returns(Field) }
        def field_of(descriptor)
          if descriptor.label == :repeated
            # Here we're going to check if the submsg_name is named according to
            # how Google names map entries.
            # https://github.com/protocolbuffers/protobuf/blob/f82e26/ruby/ext/google/protobuf_c/defs.c#L1963-L1966
            if descriptor.submsg_name.to_s.end_with?("_MapEntry_#{descriptor.name}")
              key = descriptor.subtype.lookup('key')
              value = descriptor.subtype.lookup('value')

              key_type = type_of(key)
              value_type = type_of(value)
              type = "Google::Protobuf::Map[#{key_type}, #{value_type}]"

              default_args = [key.type.inspect, value.type.inspect]
              default_args << value_type if %i[enum message].include?(value.type)

              Field.new(
                name: descriptor.name,
                type: type,
                init_type: "T.any(#{type}, T::Hash[#{key_type}, #{value_type}])",
                default: "Google::Protobuf::Map.new(#{default_args.join(', ')})"
              )
            else
              elem_type = type_of(descriptor)
              type = "Google::Protobuf::RepeatedField[#{elem_type}]"

              default_args = [descriptor.type.inspect]
              default_args << elem_type if %i[enum message].include?(descriptor.type)

              Field.new(
                name: descriptor.name,
                type: type,
                init_type: "T.any(#{type}, T::Array[#{elem_type}])",
                default: "Google::Protobuf::RepeatedField.new(#{default_args.join(', ')})"
              )
            end
          else
            type = type_of(descriptor)

            Field.new(
              name: descriptor.name,
              type: type,
              init_type: type,
              default: "nil"
            )
          end
        end

        sig do
          params(
            klass: Parlour::RbiGenerator::Namespace,
            desc: Google::Protobuf::FieldDescriptor,
          ).returns(Field)
        end
        def create_descriptor_method(klass, desc)
          field = field_of(desc)

          create_method(
            klass,
            field.name,
            return_type: field.type
          )

          create_method(
            klass,
            "#{field.name}=",
            parameters: [
              Parlour::RbiGenerator::Parameter.new("value", type: field.type),
            ],
            return_type: field.type
          )

          field
        end
      end
    end
  end
end
