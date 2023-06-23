# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ProtobufSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::Protobuf" do
          describe "gather_constants" do
            it "gathers no constants if there are no Google::Protobuf classes" do
              add_ruby_file("content.rb", <<~RUBY)
                Google::Protobuf::DescriptorPool.generated_pool.build do
                end
              RUBY

              assert(gathered_constants.all? { |constant| constant.start_with?("Google::Protobuf") })
            end

            it "gathers only classes with Protobuf Module" do
              add_ruby_file("content.rb", <<~RUBY)
                Google::Protobuf::DescriptorPool.generated_pool.build do
                  add_file("cart.proto", :syntax => :proto3) do
                    add_message "MyCart" do
                      optional :shop_id, :int32, 1
                      optional :customer_id, :int32, 2
                    end
                  end
                end

                Cart = Google::Protobuf::DescriptorPool.generated_pool.lookup("MyCart").msgclass
              RUBY

              assert_equal(["Cart"], gathered_constants.reject { |constant| constant.start_with?("Google::Protobuf") })
              assert_includes(gathered_constants, "Google::Protobuf::Map")
              assert_includes(gathered_constants, "Google::Protobuf::RepeatedField")
              refute_includes(gathered_constants, "Google::Protobuf::AbstractMessage")
            end
          end

          describe "decorate" do
            it "generates methods in RBI files for classes with Protobuf with integer field type" do
              add_ruby_file("protobuf.rb", <<~RUBY)
                Google::Protobuf::DescriptorPool.generated_pool.build do
                  add_file("cart.proto", :syntax => :proto3) do
                    add_message "MyCart" do
                      optional :shop_id, :int32, 1
                      optional :customer_id, :int32, 2
                    end
                  end
                end

                Cart = Google::Protobuf::DescriptorPool.generated_pool.lookup("MyCart").msgclass
              RUBY

              expected = <<~RBI
                # typed: strong

                class Cart
                  sig { params(customer_id: T.nilable(Integer), shop_id: T.nilable(Integer)).void }
                  def initialize(customer_id: nil, shop_id: nil); end

                  sig { void }
                  def clear_customer_id; end

                  sig { void }
                  def clear_shop_id; end

                  sig { returns(Integer) }
                  def customer_id; end

                  sig { params(value: Integer).void }
                  def customer_id=(value); end

                  sig { returns(Integer) }
                  def shop_id; end

                  sig { params(value: Integer).void }
                  def shop_id=(value); end
                end
              RBI

              assert_equal(expected, rbi_for(:Cart))
            end

            it "generates methods in RBI files for classes with Protobuf with string field type" do
              add_ruby_file("protobuf.rb", <<~RUBY)
                Google::Protobuf::DescriptorPool.generated_pool.build do
                  add_file("cart.proto", :syntax => :proto3) do
                    add_message "MyCart" do
                      optional :events, :string, 1
                    end
                  end
                end

                Cart = Google::Protobuf::DescriptorPool.generated_pool.lookup("MyCart").msgclass
              RUBY

              expected = <<~RBI
                # typed: strong

                class Cart
                  sig { params(events: T.nilable(String)).void }
                  def initialize(events: nil); end

                  sig { void }
                  def clear_events; end

                  sig { returns(String) }
                  def events; end

                  sig { params(value: String).void }
                  def events=(value); end
                end
              RBI

              assert_equal(expected, rbi_for(:Cart))
            end

            it "generates methods in RBI files for classes with Protobuf with message field type" do
              add_ruby_file("protobuf.rb", <<~RUBY)
                require 'google/protobuf/timestamp_pb'
                require 'google/protobuf/wrappers_pb'

                Google::Protobuf::DescriptorPool.generated_pool.build do
                  add_file("cart.proto", :syntax => :proto3) do
                    add_message "MyCart" do
                      optional :cart_item_index, :message, 1, "google.protobuf.UInt64Value"
                    end
                  end
                end

                Cart = Google::Protobuf::DescriptorPool.generated_pool.lookup("MyCart").msgclass
              RUBY

              expected = <<~RBI
                # typed: strong

                class Cart
                  sig { params(cart_item_index: T.nilable(Google::Protobuf::UInt64Value)).void }
                  def initialize(cart_item_index: nil); end

                  sig { returns(T.nilable(Google::Protobuf::UInt64Value)) }
                  def cart_item_index; end

                  sig { params(value: T.nilable(Google::Protobuf::UInt64Value)).void }
                  def cart_item_index=(value); end

                  sig { void }
                  def clear_cart_item_index; end
                end
              RBI

              assert_equal(expected, rbi_for(:Cart))
            end

            it "generates methods in RBI files for classes with Protobuf with enum field" do
              add_ruby_file("protobuf.rb", <<~RUBY)
                require 'google/protobuf/timestamp_pb'
                require 'google/protobuf/wrappers_pb'

                Google::Protobuf::DescriptorPool.generated_pool.build do
                  add_file("cart.proto", :syntax => :proto3) do
                    add_message "MyCart" do
                      optional :value_type, :enum, 1, "VALUE_TYPE"
                    end
                    add_enum "VALUE_TYPE" do
                      value :NULL, 0
                      value :FIXED_AMOUNT, 1
                      value :PERCENTAGE, 2
                    end
                  end
                end

                Cart = Google::Protobuf::DescriptorPool.generated_pool.lookup("MyCart").msgclass
                Cart::VALUE_TYPE = Google::Protobuf::DescriptorPool.generated_pool.lookup("VALUE_TYPE").enummodule
              RUBY

              expected = <<~RBI
                # typed: strong

                class Cart
                  sig { params(value_type: T.nilable(T.any(Symbol, Integer))).void }
                  def initialize(value_type: nil); end

                  sig { void }
                  def clear_value_type; end

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

            it "generates methods in RBI files for classes with Protobuf with enum field with defined type" do
              add_ruby_file("protobuf.rb", <<~RUBY)
                require 'google/protobuf/timestamp_pb'
                require 'google/protobuf/wrappers_pb'

                Google::Protobuf::DescriptorPool.generated_pool.build do
                  add_file("cart.proto", :syntax => :proto3) do
                    add_message "MyCart" do
                      optional :value_type, :enum, 1, "MyCart.MYVALUETYPE"
                    end
                    add_enum "MyCart.MYVALUETYPE" do
                      value :ACROSS, 0
                      value :ONE, 1
                      value :EACH, 2
                    end
                  end
                end

                Cart = Google::Protobuf::DescriptorPool.generated_pool.lookup("MyCart").msgclass
                Cart::MYVALUETYPE = Google::Protobuf::DescriptorPool.generated_pool.lookup("MyCart.MYVALUETYPE").enummodule
              RUBY

              expected = <<~RBI
                # typed: strong

                class Cart
                  sig { params(value_type: T.nilable(T.any(Symbol, Integer))).void }
                  def initialize(value_type: nil); end

                  sig { void }
                  def clear_value_type; end

                  sig { returns(T.any(Symbol, Integer)) }
                  def value_type; end

                  sig { params(value: T.any(Symbol, Integer)).void }
                  def value_type=(value); end
                end
              RBI

              assert_equal(expected, rbi_for(:Cart))
            end

            it "generates methods in RBI files for repeated fields in Protobufs" do
              add_ruby_file("protobuf.rb", <<~RUBY)
                require 'google/protobuf/wrappers_pb'

                Google::Protobuf::DescriptorPool.generated_pool.build do
                  add_file("cart.proto", :syntax => :proto3) do
                    add_message "MyCart" do
                      repeated :customer_ids, :int32, 1
                      repeated :indices, :message, 2, "google.protobuf.UInt64Value"
                    end
                  end
                end

                Cart = Google::Protobuf::DescriptorPool.generated_pool.lookup("MyCart").msgclass
              RUBY

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

            it "generates methods in RBI files for map fields in Protobufs" do
              add_ruby_file("protobuf.rb", <<~RUBY)
                require 'google/protobuf/wrappers_pb'

                Google::Protobuf::DescriptorPool.generated_pool.build do
                  add_file("cart.proto", :syntax => :proto3) do
                    add_message "MyCart" do
                      map :customers, :string, :int32, 1
                      map :stores, :string, :message, 2, "google.protobuf.UInt64Value"
                    end
                  end
                end

                Cart = Google::Protobuf::DescriptorPool.generated_pool.lookup("MyCart").msgclass
              RUBY

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
              add_ruby_file("protobuf.rb", <<~RUBY)
                require 'google/protobuf/timestamp_pb'
                require 'google/protobuf/wrappers_pb'

                Google::Protobuf::DescriptorPool.generated_pool.build do
                  add_file("cart.proto", :syntax => :proto3) do
                    add_message "MyCart" do
                      optional :shop_id, :int32, 1
                      optional :customer_id, :int64, 2
                      optional :number_value, :double, 3
                      optional :string_value, :string, 4
                      optional :bool_value, :bool, 5
                      optional :money_value, :float, 6
                      optional :byte_value, :bytes, 7
                      optional :id, :uint64, 8
                      optional :item_id, :uint32, 9
                    end
                  end
                end

                Cart = Google::Protobuf::DescriptorPool.generated_pool.lookup("MyCart").msgclass
              RUBY

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
              add_ruby_file("protobuf.rb", <<~RUBY)
                Google::Protobuf::DescriptorPool.generated_pool.build do
                  add_file("cart.proto", :syntax => :proto3) do
                    add_message "MyCart" do
                      optional :ShopID, :int32, 1
                      optional :ShopName, :string, 2
                    end
                  end
                end

                Cart = Google::Protobuf::DescriptorPool.generated_pool.lookup("MyCart").msgclass
              RUBY

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

                  sig { void }
                  def clear_ShopID; end

                  sig { void }
                  def clear_ShopName; end
                end
              RBI

              assert_equal(expected, rbi_for(:Cart))
            end

            it "generates methods in RBI files with oneof fields" do
              add_ruby_file("protobuf.rb", <<~RUBY)
                Google::Protobuf::DescriptorPool.generated_pool.build do
                  add_file("cart.proto", :syntax => :proto3) do
                    add_message "MyCart" do
                      oneof :contact_info do
                        optional :phone_number, :int32, 1
                        optional :email, :string, 2
                      end
                    end
                  end
                end

                Cart = Google::Protobuf::DescriptorPool.generated_pool.lookup("MyCart").msgclass
              RUBY

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

            it "handles map and repeating types with anonymous subtype message classes by mapping them to T.untyped" do
              add_ruby_file("protobuf.rb", <<~RUBY)
                Google::Protobuf::DescriptorPool.generated_pool.build do
                  add_file("cart.proto", :syntax => :proto3) do
                    add_message "CartEntry" do
                      optional :key, :string, 1
                      optional :value, :string, 2
                    end
                    add_message "NonMapEntry" do
                      optional :key, :string, 1
                      optional :value, :string, 2
                    end
                    add_message "MyCart" do
                      map :tables, :string, :message, 1, "CartEntry"
                      repeated :items, :message, 2, "NonMapEntry"
                    end
                  end
                end

                Cart = Google::Protobuf::DescriptorPool.generated_pool.lookup("MyCart").msgclass
                # we intentionally don't define `CartEntry` or `NonMapEntry` as constants, so that
                # those message classes stay anonymous, which we expect to be mapped to `T.untyped`
              RUBY

              expected = <<~RBI
                # typed: strong

                class Cart
                  sig { params(items: T.nilable(T.any(Google::Protobuf::RepeatedField[T.untyped], T::Array[T.untyped])), tables: T.nilable(T.any(Google::Protobuf::Map[String, T.untyped], T::Hash[String, T.untyped]))).void }
                  def initialize(items: T.unsafe(nil), tables: T.unsafe(nil)); end

                  sig { void }
                  def clear_items; end

                  sig { void }
                  def clear_tables; end

                  sig { returns(Google::Protobuf::RepeatedField[T.untyped]) }
                  def items; end

                  sig { params(value: Google::Protobuf::RepeatedField[T.untyped]).void }
                  def items=(value); end

                  sig { returns(Google::Protobuf::Map[String, T.untyped]) }
                  def tables; end

                  sig { params(value: Google::Protobuf::Map[String, T.untyped]).void }
                  def tables=(value); end
                end
              RBI

              assert_equal(expected, rbi_for(:Cart))
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
      end
    end
  end
end
