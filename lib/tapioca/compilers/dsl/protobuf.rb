# typed: strict
# frozen_string_literal: true

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
        class Field < T::Struct
          prop :name, String
          prop :type, String
          prop :setter_type, String
          prop :init_type, String
          prop :default, String
        end

        extend T::Sig

        sig { override.params(root: RBI::Tree, constant: Module).void }
        def decorate(root, constant)
          root.create_path(constant) do |klass|
            if constant == Google::Protobuf::RepeatedField
              create_type_members(klass, "Elem")
            elsif constant == Google::Protobuf::Map
              create_type_members(klass, "Key", "Value")
            else
              descriptor = T.let(T.unsafe(constant).descriptor,
                T.any(Google::Protobuf::Descriptor, Google::Protobuf::EnumDescriptor))

              if descriptor.is_a?(Google::Protobuf::EnumDescriptor)
                descriptor.to_h.each do |sym, val|
                  klass.create_constant(sym.to_s, value: val.to_s)
                end
              else
                fields = descriptor.map { |desc| create_descriptor_method(klass, desc) }
                fields.sort_by!(&:name)

                parameters = fields.map do |field|
                  create_kw_opt_param(field.name, type: field.init_type, default: field.default)
                end

                klass.create_method("initialize", parameters: parameters, return_type: "void")
              end
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          marker = Google::Protobuf::MessageExts::ClassMethods

          enum_modules = ObjectSpace.each_object(Google::Protobuf::EnumDescriptor).map do |desc|
            T.cast(desc, Google::Protobuf::EnumDescriptor).enummodule
          end

          results = T.cast(ObjectSpace.each_object(marker).to_a, T::Array[Module]).concat(enum_modules)
          results.any? ? results + [Google::Protobuf::RepeatedField, Google::Protobuf::Map] : []
        end

        private

        sig { params(klass: RBI::Scope, names: String).void }
        def create_type_members(klass, *names)
          klass.create_extend("T::Generic")

          names.each do |name|
            klass.create_type_member(name)
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
            "T.any(Symbol, Integer)"
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
              key = descriptor.subtype.lookup("key")
              value = descriptor.subtype.lookup("value")

              key_type = type_of(key)
              value_type = type_of(value)
              type = "Google::Protobuf::Map[#{key_type}, #{value_type}]"

              default_args = [key.type.inspect, value.type.inspect]
              default_args << value_type if [:enum, :message].include?(value.type)

              Field.new(
                name: descriptor.name,
                type: type,
                setter_type: type,
                init_type: "T.nilable(T.any(#{type}, T::Hash[#{key_type}, #{value_type}]))",
                default: "Google::Protobuf::Map.new(#{default_args.join(", ")})"
              )
            else
              elem_type = type_of(descriptor)
              type = "Google::Protobuf::RepeatedField[#{elem_type}]"

              default_args = [descriptor.type.inspect]
              default_args << elem_type if [:enum, :message].include?(descriptor.type)

              Field.new(
                name: descriptor.name,
                type: type,
                setter_type: type,
                init_type: "T.nilable(T.any(#{type}, T::Array[#{elem_type}]))",
                default: "Google::Protobuf::RepeatedField.new(#{default_args.join(", ")})"
              )
            end
          else
            type = type_of(descriptor)

            Field.new(
              name: descriptor.name,
              type: type,
              setter_type: type,
              init_type: "T.nilable(#{type})",
              default: "nil"
            )
          end
        end

        sig do
          params(
            klass: RBI::Scope,
            desc: Google::Protobuf::FieldDescriptor,
          ).returns(Field)
        end
        def create_descriptor_method(klass, desc)
          field = field_of(desc)

          klass.create_method(
            field.name,
            return_type: field.type
          )

          klass.create_method(
            "#{field.name}=",
            parameters: [create_param("value", type: field.setter_type)],
            return_type: "void"
          )

          field
        end
      end
    end
  end
end
