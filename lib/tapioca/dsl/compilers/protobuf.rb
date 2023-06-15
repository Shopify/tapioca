# typed: strict
# frozen_string_literal: true

begin
  require "google/protobuf"
rescue LoadError
  return
end

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::Protobuf` decorates RBI files for subclasses of
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
      # this compiler will produce the RBI file `cart.rbi` with the following content:
      #
      # ~~~rbi
      # # cart.rbi
      # # typed: strong
      # class Cart
      #   sig { returns(Integer) }
      #   def customer_id; end
      #
      #   sig { params(value: Integer).returns(Integer) }
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
      #
      # Please note that you might have to ignore the originally generated Protobuf Ruby files
      # to avoid _Redefining constant_ issues when doing type checking.
      # Do this by extending your Sorbet config file:
      #
      # ~~~
      # --ignore=/path/to/proto/cart_pb.rb
      # ~~~
      class Protobuf < Compiler
        class Field < T::Struct
          prop :name, String
          prop :type, RBI::Type
          prop :init_type, RBI::Type
          prop :default, String
        end

        extend T::Sig

        ConstantType = type_member { { fixed: Module } }

        FIELD_RE = /^[a-z_][a-zA-Z0-9_]*$/

        sig { override.void }
        def decorate
          root.create_path(constant) do |klass|
            if constant == Google::Protobuf::RepeatedField
              create_type_members(klass, "Elem")
            elsif constant == Google::Protobuf::Map
              create_type_members(klass, "Key", "Value")
            else
              descriptor = T.unsafe(constant).descriptor

              case descriptor
              when Google::Protobuf::EnumDescriptor
                descriptor.to_h.each do |sym, val|
                  # For each enum value, create a namespaced constant on the root rather than an un-namespaced
                  # constant within the class. This is because un-namespaced constants might conflict with reserved
                  # Ruby words, such as "BEGIN." By namespacing them, we avoid this problem.
                  #
                  # Invalid syntax:
                  # class Foo
                  #   BEGIN = 3
                  # end
                  #
                  # Valid syntax:
                  # Foo::BEGIN = 3
                  root.create_constant("#{constant}::#{sym}", value: val.to_s)
                end

                klass.create_method(
                  "lookup",
                  parameters: [create_param("number", type: RBI::Type.simple("::Integer"))],
                  return_type: RBI::Type.simple("::Symbol").nilable,
                  class_method: true,
                )
                klass.create_method(
                  "resolve",
                  parameters: [create_param("symbol", type: RBI::Type.simple("::Symbol"))],
                  return_type: RBI::Type.simple("::Integer").nilable,
                  class_method: true,
                )
                klass.create_method(
                  "descriptor",
                  return_type: RBI::Type.simple("::Google::Protobuf::EnumDescriptor"),
                  class_method: true,
                )
              when Google::Protobuf::Descriptor
                descriptor.each_oneof { |oneof| create_oneof_method(klass, oneof) }
                fields = descriptor.map { |desc| create_descriptor_method(klass, desc) }
                fields.sort_by!(&:name)

                parameters = fields.map do |field|
                  create_kw_opt_param(field.name, type: field.init_type, default: field.default)
                end

                if fields.all? { |field| FIELD_RE.match?(field.name) }
                  klass.create_method("initialize", parameters: parameters, return_type: RBI::Type.void)
                else
                  # One of the fields has an incorrect name for a named parameter so creating the default initialize for
                  # it would create a RBI with a syntax error.
                  # The workaround is to create an initialize that takes a **kwargs instead.
                  kwargs_parameter = create_kw_rest_param("fields", type: RBI::Type.untyped)
                  klass.create_method("initialize", parameters: [kwargs_parameter], return_type: RBI::Type.void)
                end
              else
                add_error(<<~MSG.strip)
                  Unexpected descriptor class `#{descriptor.class.name}` for `#{constant}`
                MSG
              end
            end
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            marker = Google::Protobuf::MessageExts::ClassMethods

            enum_modules = ObjectSpace.each_object(Google::Protobuf::EnumDescriptor).map do |desc|
              T.cast(desc, Google::Protobuf::EnumDescriptor).enummodule
            end

            results = if Google::Protobuf.const_defined?(:AbstractMessage)
              abstract_message_const = ::Google::Protobuf.const_get(:AbstractMessage)
              descendants_of(abstract_message_const) - [abstract_message_const]
            else
              T.cast(
                ObjectSpace.each_object(marker).to_a,
                T::Array[Module],
              )
            end

            results = results.concat(enum_modules)
            results.any? ? results + [Google::Protobuf::RepeatedField, Google::Protobuf::Map] : []
          end
        end

        private

        sig { params(klass: RBI::Scope, names: String).void }
        def create_type_members(klass, *names)
          klass.create_extend("T::Generic")

          names.each do |name|
            klass.create_type_variable(name, type: "type_member")
          end
        end

        sig do
          params(
            descriptor: Google::Protobuf::FieldDescriptor,
          ).returns(RBI::Type)
        end
        def type_of(descriptor)
          case descriptor.type
          when :enum
            # According to https://developers.google.com/protocol-buffers/docs/reference/ruby-generated#enum
            # > You may assign either a number or a symbol to an enum field.
            # > When reading the value back, it will be a symbol if the enum
            # > value is known, or a number if it is unknown. Since proto3 uses
            # > open enum semantics, any number may be assigned to an enum
            # > field, even if it was not defined in the enum.
            RBI::Type.any(RBI::Type.simple("::Symbol"), RBI::Type.simple("::Integer"))
          when :message
            RBI::Type.simple(T.must(qualified_name_of(descriptor.subtype.msgclass)))
          when :int32, :int64, :uint32, :uint64
            RBI::Type.simple("::Integer")
          when :double, :float
            RBI::Type.simple("::Float")
          when :bool
            RBI::Type.boolean
          when :string, :bytes
            RBI::Type.simple("::String")
          else
            RBI::Type.untyped
          end
        end

        sig { params(descriptor: Google::Protobuf::FieldDescriptor).returns(T::Boolean) }
        def nilable_descriptor?(descriptor)
          descriptor.label == :optional && descriptor.type == :message
        end

        sig { params(descriptor: Google::Protobuf::FieldDescriptor).returns(Field) }
        def field_of(descriptor)
          if descriptor.label == :repeated
            # Here we're going to check if the submsg_name is named according to
            # how Google names map entries.
            # https://github.com/protocolbuffers/protobuf/blob/f82e26/ruby/ext/google/protobuf_c/defs.c#L1963-L1966
            if descriptor.submsg_name.to_s.end_with?("_MapEntry_#{descriptor.name}") ||
                descriptor.submsg_name.to_s.end_with?("FieldsEntry")
              key = descriptor.subtype.lookup("key")
              value = descriptor.subtype.lookup("value")

              key_type = type_of(key)
              value_type = type_of(value)
              type = RBI::Type.generic("Google::Protobuf::Map", key_type, value_type)

              default_args = [key.type.inspect, value.type.inspect]
              default_args << T.cast(value_type, RBI::Type::Simple).name if [:enum, :message].include?(value.type)

              Field.new(
                name: descriptor.name,
                type: type,
                init_type: RBI::Type.any(type, RBI::Type.generic("T::Hash", key_type, value_type)).nilable,
                default: "Google::Protobuf::Map.new(#{default_args.join(", ")})",
              )
            else
              elem_type = type_of(descriptor)
              type = RBI::Type.generic("Google::Protobuf::RepeatedField", elem_type)

              default_args = [descriptor.type.inspect]
              default_args << T.cast(elem_type, RBI::Type::Simple).name if [:enum, :message].include?(descriptor.type)

              Field.new(
                name: descriptor.name,
                type: type,
                init_type: RBI::Type.any(type, RBI::Type.generic("T::Array", elem_type)).nilable,
                default: "Google::Protobuf::RepeatedField.new(#{default_args.join(", ")})",
              )
            end
          else
            type = type_of(descriptor)
            nilable_type = type.nilable
            type = nilable_type if nilable_descriptor?(descriptor)

            Field.new(
              name: descriptor.name,
              type: type,
              init_type: nilable_type,
              default: "nil",
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
            return_type: field.type,
          )

          klass.create_method(
            "#{field.name}=",
            parameters: [create_param("value", type: field.type)],
            return_type: RBI::Type.void,
          )

          klass.create_method(
            "clear_#{field.name}",
            return_type: RBI::Type.void,
          )

          field
        end

        sig do
          params(
            klass: RBI::Scope,
            desc: Google::Protobuf::OneofDescriptor,
          ).void
        end
        def create_oneof_method(klass, desc)
          klass.create_method(
            desc.name,
            return_type: RBI::Type.simple("::Symbol").nilable,
          )
        end
      end
    end
  end
end
