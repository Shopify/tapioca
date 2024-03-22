# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ProtobufSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::Protobuf" do
          sig { void }
          def before_setup
            require "google/protobuf"
          end

          describe "gather_constants" do
            it "gathers no constants if there are no Google::Protobuf classes" do
              add_proto_file("content", "")

              assert(gathered_constants.all? { |constant| constant.start_with?("Google::Protobuf") })
            end

            it "gathers only classes with Protobuf Module" do
              add_proto_file("cart", <<~PROTO)
                syntax = "proto3";

                message Cart {
                  optional int32 shop_id = 1;
                  optional int32 customer_id = 2;
                }
              PROTO

              assert_equal(["Cart"], gathered_constants.reject { |constant| constant.start_with?("Google::Protobuf") })
              assert_includes(gathered_constants, "Google::Protobuf::Map")
              assert_includes(gathered_constants, "Google::Protobuf::RepeatedField")
              refute_includes(gathered_constants, "Google::Protobuf::AbstractMessage")
            end
          end

          describe "decorate" do
            it "generates methods in RBI files for classes with Protobuf with integer field type" do
              add_proto_file("cart", <<~PROTO)
                syntax = "proto3";

                message Cart {
                  optional int32 shop_id = 1;
                  optional int32 customer_id = 2;
                }
              PROTO

              expected = <<~RBI
                # typed: strong

                class Cart
                  sig { params(customer_id: T.nilable(Integer), shop_id: T.nilable(Integer)).void }
                  def initialize(customer_id: nil, shop_id: nil); end

                  sig { returns(T.nilable(Symbol)) }
                  def _customer_id; end

                  sig { returns(T.nilable(Symbol)) }
                  def _shop_id; end

                  sig { void }
                  def clear_customer_id; end

                  sig { void }
                  def clear_shop_id; end

                  sig { returns(Integer) }
                  def customer_id; end

                  sig { params(value: Integer).void }
                  def customer_id=(value); end

                  sig { returns(Object) }
                  def has_customer_id?; end

                  sig { returns(Object) }
                  def has_shop_id?; end

                  sig { returns(Integer) }
                  def shop_id; end

                  sig { params(value: Integer).void }
                  def shop_id=(value); end
                end
              RBI

              assert_equal(expected, rbi_for(:Cart))
            end

            it "generates methods in RBI files for classes with Protobuf with string field type" do
              add_proto_file("cart", <<~PROTO)
                syntax = "proto3";

                message Cart {
                  optional string events = 1;
                }
              PROTO

              expected = <<~RBI
                # typed: strong

                class Cart
                  sig { params(events: T.nilable(String)).void }
                  def initialize(events: nil); end

                  sig { returns(T.nilable(Symbol)) }
                  def _events; end

                  sig { void }
                  def clear_events; end

                  sig { returns(String) }
                  def events; end

                  sig { params(value: String).void }
                  def events=(value); end

                  sig { returns(Object) }
                  def has_events?; end
                end
              RBI

              assert_equal(expected, rbi_for(:Cart))
            end

            it "generates methods in RBI files for classes with Protobuf with message field type" do
              add_proto_file("cart", <<~PROTO)
                syntax = "proto3";
                import "google/protobuf/wrappers.proto";

                message Cart {
                  optional google.protobuf.UInt64Value cart_item_index = 1;
                }
              PROTO

              expected = <<~RBI
                # typed: strong

                class Cart
                  sig { params(cart_item_index: T.nilable(Google::Protobuf::UInt64Value)).void }
                  def initialize(cart_item_index: nil); end

                  sig { returns(T.nilable(Symbol)) }
                  def _cart_item_index; end

                  sig { returns(T.nilable(Google::Protobuf::UInt64Value)) }
                  def cart_item_index; end

                  sig { params(value: T.nilable(Google::Protobuf::UInt64Value)).void }
                  def cart_item_index=(value); end

                  sig { void }
                  def clear_cart_item_index; end

                  sig { returns(Object) }
                  def has_cart_item_index?; end
                end
              RBI

              assert_equal(expected, rbi_for(:Cart))
            end

            it "generates methods in RBI files for classes with Protobuf with enum field" do
              add_proto_file("cart", <<~PROTO)
                syntax = "proto3";

                message Cart {
                  enum VALUE_TYPE {
                    NULL = 0;
                    FIXED_AMOUNT = 1;
                    PERCENTAGE = 2;
                  }

                  optional VALUE_TYPE value_type = 1;
                }
              PROTO

              expected = <<~RBI
                # typed: strong

                class Cart
                  sig { params(value_type: T.nilable(T.any(Symbol, Integer))).void }
                  def initialize(value_type: nil); end

                  sig { returns(T.nilable(Symbol)) }
                  def _value_type; end

                  sig { void }
                  def clear_value_type; end

                  sig { returns(Object) }
                  def has_value_type?; end

                  sig { returns(T.any(Symbol, Integer)) }
                  def value_type; end

                  sig { params(value: T.any(Symbol, Integer)).void }
                  def value_type=(value); end
                end
              RBI

              expected_enum_rbi = <<~RBI
                # typed: strong

                module Cart::VALUE_TYPE
                  class << self
                    sig { returns(Google::Protobuf::EnumDescriptor) }
                    def descriptor; end

                    sig { params(number: Integer).returns(T.nilable(Symbol)) }
                    def lookup(number); end

                    sig { params(symbol: Symbol).returns(T.nilable(Integer)) }
                    def resolve(symbol); end
                  end
                end

                Cart::VALUE_TYPE::FIXED_AMOUNT = 1
                Cart::VALUE_TYPE::NULL = 0
                Cart::VALUE_TYPE::PERCENTAGE = 2
              RBI

              assert_equal(expected_enum_rbi, rbi_for("Cart::VALUE_TYPE"))
              assert_equal(expected, rbi_for(:Cart))
            end

            it "generates methods in RBI files for repeated fields in Protobufs" do
              add_proto_file("cart", <<~PROTO)
                syntax = "proto3";
                import "google/protobuf/wrappers.proto";

                message Cart {
                  repeated int32 customer_ids = 1;
                  repeated google.protobuf.UInt64Value indices = 2;
                }
              PROTO

              expected = <<~RBI
                # typed: strong

                class Cart
                  sig { params(customer_ids: T.nilable(T.any(Google::Protobuf::RepeatedField[Integer], T::Array[Integer])), indices: T.nilable(T.any(Google::Protobuf::RepeatedField[Google::Protobuf::UInt64Value], T::Array[Google::Protobuf::UInt64Value]))).void }
                  def initialize(customer_ids: T.unsafe(nil), indices: T.unsafe(nil)); end

                  sig { void }
                  def clear_customer_ids; end

                  sig { void }
                  def clear_indices; end

                  sig { returns(Google::Protobuf::RepeatedField[Integer]) }
                  def customer_ids; end

                  sig { params(value: Google::Protobuf::RepeatedField[Integer]).void }
                  def customer_ids=(value); end

                  sig { returns(Google::Protobuf::RepeatedField[Google::Protobuf::UInt64Value]) }
                  def indices; end

                  sig { params(value: Google::Protobuf::RepeatedField[Google::Protobuf::UInt64Value]).void }
                  def indices=(value); end
                end
              RBI

              assert_equal(expected, rbi_for(:Cart))
            end

            it "generates methods in RBI files for classes with Protobuf with non-optional integer field type" do
              add_proto_file("cart", <<~PROTO)
                syntax = "proto3";

                message Cart {
                  int32 shop_id = 1;
                }
              PROTO

              expected = <<~RBI
                # typed: strong

                class Cart
                  sig { params(shop_id: T.nilable(Integer)).void }
                  def initialize(shop_id: nil); end

                  sig { void }
                  def clear_shop_id; end

                  sig { returns(Integer) }
                  def shop_id; end

                  sig { params(value: Integer).void }
                  def shop_id=(value); end
                end
              RBI

              assert_equal(expected, rbi_for(:Cart))
            end

            it "generates methods in RBI files for map fields in Protobufs" do
              add_proto_file("cart", <<~PROTO)
                syntax = "proto3";
                import "google/protobuf/wrappers.proto";

                message Cart {
                  map<string, int32> customers = 1;
                  map<string, google.protobuf.UInt64Value> stores = 2;
                }
              PROTO

              expected = <<~RBI
                # typed: strong

                class Cart
                  sig { params(customers: T.nilable(T.any(Google::Protobuf::Map[String, Integer], T::Hash[String, Integer])), stores: T.nilable(T.any(Google::Protobuf::Map[String, Google::Protobuf::UInt64Value], T::Hash[String, Google::Protobuf::UInt64Value]))).void }
                  def initialize(customers: T.unsafe(nil), stores: T.unsafe(nil)); end

                  sig { void }
                  def clear_customers; end

                  sig { void }
                  def clear_stores; end

                  sig { returns(Google::Protobuf::Map[String, Integer]) }
                  def customers; end

                  sig { params(value: Google::Protobuf::Map[String, Integer]).void }
                  def customers=(value); end

                  sig { returns(Google::Protobuf::Map[String, Google::Protobuf::UInt64Value]) }
                  def stores; end

                  sig { params(value: Google::Protobuf::Map[String, Google::Protobuf::UInt64Value]).void }
                  def stores=(value); end
                end
              RBI

              assert_equal(expected, rbi_for(:Cart))
            end

            it "generates methods in RBI files for classes with Protobuf with all types" do
              add_proto_file("cart", <<~PROTO)
                syntax = "proto3";
                import "google/protobuf/wrappers.proto";

                message Cart {
                  optional int32 shop_id = 1;
                  optional int64 customer_id = 2;
                  optional double number_value = 3;
                  optional string string_value = 4;
                  optional bool bool_value = 5;
                  optional float money_value = 6;
                  optional bytes byte_value = 7;
                  optional uint64 id = 8;
                  optional uint32 item_id = 9;
                }
              PROTO

              rbi_output = rbi_for(:Cart)

              assert_includes(rbi_output, indented(<<~RBI, 2))
                sig { params(value: T::Boolean).void }
                def bool_value=(value); end
              RBI

              assert_includes(rbi_output, indented(<<~RBI, 2))
                sig { params(value: String).void }
                def byte_value=(value); end
              RBI

              assert_includes(rbi_output, indented(<<~RBI, 2))
                sig { params(value: Integer).void }
                def customer_id=(value); end
              RBI

              assert_includes(rbi_output, indented(<<~RBI, 2))
                sig { params(value: Integer).void }
                def id=(value); end
              RBI

              assert_includes(rbi_output, indented(<<~RBI, 2))
                sig { params(value: Integer).void }
                def item_id=(value); end
              RBI

              assert_includes(rbi_output, indented(<<~RBI, 2))
                sig { params(value: Float).void }
                def money_value=(value); end
              RBI

              assert_includes(rbi_output, indented(<<~RBI, 2))
                sig { params(value: Float).void }
                def number_value=(value); end
              RBI

              assert_includes(rbi_output, indented(<<~RBI, 2))
                sig { params(value: Integer).void }
                def shop_id=(value); end
              RBI

              assert_includes(rbi_output, indented(<<~RBI, 2))
                sig { params(value: String).void }
                def string_value=(value); end
              RBI
            end

            it "generates methods in RBI files with sanitized field names" do
              add_proto_file("cart", <<~PROTO)
                syntax = "proto3";

                message Cart {
                  optional int32 ShopID = 1;
                  optional string ShopName = 2;
                }
              PROTO

              expected = <<~RBI
                # typed: strong

                class Cart
                  sig { params(fields: T.untyped).void }
                  def initialize(**fields); end

                  sig { returns(Integer) }
                  def ShopID; end

                  sig { params(value: Integer).void }
                  def ShopID=(value); end

                  sig { returns(String) }
                  def ShopName; end

                  sig { params(value: String).void }
                  def ShopName=(value); end

                  sig { returns(T.nilable(Symbol)) }
                  def _ShopID; end

                  sig { returns(T.nilable(Symbol)) }
                  def _ShopName; end

                  sig { void }
                  def clear_ShopID; end

                  sig { void }
                  def clear_ShopName; end

                  sig { returns(Object) }
                  def has_ShopID?; end

                  sig { returns(Object) }
                  def has_ShopName?; end
                end
              RBI

              assert_equal(expected, rbi_for(:Cart))
            end

            it "generates methods in RBI files with oneof fields" do
              add_proto_file("cart", <<~PROTO)
                syntax = "proto3";

                message Cart {
                  oneof contact_info {
                    int32 phone_number = 1;
                    string email = 2;
                  }
                }
              PROTO

              rbi_output = rbi_for(:Cart)

              assert_includes(rbi_output, indented(<<~RBI, 2))

                sig { void }
                def clear_email; end

                sig { void }
                def clear_phone_number; end

                sig { returns(T.nilable(Symbol)) }
                def contact_info; end
              RBI
            end

            it "shows an error for an unexpected descriptor class" do
              expect_dsl_compiler_errors!

              add_ruby_file("protobuf.rb", <<~RUBY)
                Cart = Class.new(::Google::Protobuf.const_get(:AbstractMessage))
              RUBY

              rbi_output = rbi_for(:Cart)

              assert_equal(<<~RBI, rbi_output)
                # typed: strong

                class Cart; end
              RBI
              assert_equal(["Unexpected descriptor class `NilClass` for `Cart`"], generated_errors)
            end

            it "handles FieldsEntry types just like MapEntry types" do
              add_ruby_file("content.rb", <<~RUBY)
                require 'google/protobuf/struct_pb'
              RUBY

              expected = <<~RBI
                # typed: strong

                class Google::Protobuf::Struct
                  sig { params(fields: T.nilable(T.any(Google::Protobuf::Map[String, Google::Protobuf::Value], T::Hash[String, Google::Protobuf::Value]))).void }
                  def initialize(fields: T.unsafe(nil)); end

                  sig { void }
                  def clear_fields; end

                  sig { returns(Google::Protobuf::Map[String, Google::Protobuf::Value]) }
                  def fields; end

                  sig { params(value: Google::Protobuf::Map[String, Google::Protobuf::Value]).void }
                  def fields=(value); end
                end
              RBI
              assert_equal(expected, rbi_for("Google::Protobuf::Struct"))
            end

            it "handles map types regardless of their name" do
              # This is test is based on this definition from `google-cloud-bigtable` gem that was causing issues:
              # https://github.com/googleapis/google-cloud-ruby/blob/9de1ce5bf74105383fc46060600d5293f8692035/google-cloud-bigtable-admin-v2/lib/google/bigtable/admin/v2/bigtable_instance_admin_pb.rb#L20
              add_ruby_file("protobuf.rb", <<~RUBY)
                require "base64"
                require 'google/protobuf'

                # This is how the new protobuf compiler (protoc) generates `xx_pb.rb` files.
                # It embeds the descriptor data as binary into a string and parses it into the pool.
                # The following is a simplified result of running `protoc --ruby_out=. cart.proto` with `cart.proto` as:
                # ```
                # syntax = "proto3";
                #
                # message MyCart {
                #   message Progress {
                #     enum State {
                #       STATE_UNSPECIFIED = 0;
                #       PENDING = 1;
                #       COMPLETED = 2;
                #     }
                #
                #     State state = 4;
                #   }
                #
                #   map<string, Progress> progress = 4;
                # }
                # ```
                # which is based on the failing case from https://github.com/googleapis/googleapis/blob/master/google/bigtable/admin/v2/bigtable_instance_admin.proto#L486-L536
                #
                # I encoded the data as Base64 since embedding the binary string was giving me invalid byte sequence errors.
                descriptor_data = Base64.decode64("CgpjYXJ0LnByb3RvIuMBCgZNeUNhcnQSJwoIcHJvZ3Jlc3MYBCADKAsyFS5NeUNhcnQuUHJvZ3Jlc3NFbnRyeRptCghQcm9ncmVzcxIlCgVzdGF0ZRgEIAEoDjIWLk15Q2FydC5Qcm9ncmVzcy5TdGF0ZSI6CgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgsKB1BFTkRJTkcQARINCglDT01QTEVURUQQAhpBCg1Qcm9ncmVzc0VudHJ5EgsKA2tleRgBIAEoCRIfCgV2YWx1ZRgCIAEoCzIQLk15Q2FydC5Qcm9ncmVzczoCOAFiBnByb3RvMw==")
                pool = Google::Protobuf::DescriptorPool.generated_pool
                pool.add_serialized_file(descriptor_data)

                Cart = Google::Protobuf::DescriptorPool.generated_pool.lookup("MyCart").msgclass
                Cart::Progress = Google::Protobuf::DescriptorPool.generated_pool.lookup("MyCart.Progress").msgclass
                Cart::Progress::State = Google::Protobuf::DescriptorPool.generated_pool.lookup("MyCart.Progress.State").enummodule
              RUBY

              expected = <<~RBI
                # typed: strong

                class Cart
                  sig { params(progress: T.nilable(T.any(Google::Protobuf::Map[String, Cart::Progress], T::Hash[String, Cart::Progress]))).void }
                  def initialize(progress: T.unsafe(nil)); end

                  sig { void }
                  def clear_progress; end

                  sig { returns(Google::Protobuf::Map[String, Cart::Progress]) }
                  def progress; end

                  sig { params(value: Google::Protobuf::Map[String, Cart::Progress]).void }
                  def progress=(value); end
                end
              RBI

              assert_equal(expected, rbi_for(:Cart))
            end
          end
        end

        private

        sig { params(name: String, content: String, require_file: T::Boolean).void }
        def add_proto_file(name, content, require_file: true)
          add_content_file("proto/#{name}.proto", content).tap do |proto_path|
            lib_path = tmp_path("lib")
            proto_dir = File.dirname(proto_path)
            _, stderr, status = Open3.capture3("protoc --proto_path=#{proto_dir} --ruby_out=#{lib_path} #{proto_path}")
            raise "Error executing protoc: #{stderr}" unless status.success?

            Tapioca.silence_warnings { require("#{lib_path}/#{name}_pb.rb") } if require_file
          end
        end
      end
    end
  end
end
