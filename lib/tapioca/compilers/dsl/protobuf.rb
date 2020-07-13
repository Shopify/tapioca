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
