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
        extend T::Sig

        sig do
          override.params(
            root: Parlour::RbiGenerator::Namespace,
            constant: T.class_of(Google::Protobuf::MessageExts)
          ).void
        end
        def decorate(root, constant)
          descriptor = T.let(T.unsafe(constant).descriptor, Google::Protobuf::Descriptor)
          return unless descriptor.any?

          root.path(constant) do |klass|
            descriptor.each do |desc|
              create_descriptor_method(klass, desc)
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          classes = T.cast(ObjectSpace.each_object(Class), T::Enumerable[Class])
          classes.select { |c| c < Google::Protobuf::MessageExts && !c.singleton_class? }
        end

        private

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

        sig do
          params(
            klass: Parlour::RbiGenerator::Namespace,
            desc: Google::Protobuf::FieldDescriptor,
          ).void
        end
        def create_descriptor_method(klass, desc)
          name = desc.name
          type = type_of(desc)

          create_method(
            klass,
            name,
            return_type: type
          )

          create_method(
            klass,
            "#{name}=",
            parameters: [
              Parlour::RbiGenerator::Parameter.new("value", type: type),
            ],
            return_type: type
          )
        end
      end
    end
  end
end
