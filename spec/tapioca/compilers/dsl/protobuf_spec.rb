# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ProtobufSpec < DslSpec
  describe("#gather_constants") do
    after(:each) do
      T.unsafe(self).assert_no_generated_errors
    end

    it("gathers no constants if there are no Google::Protobuf classes") do
      add_ruby_file("content.rb", <<~RUBY)
        Google::Protobuf::DescriptorPool.generated_pool.build do
        end
      RUBY

      assert_equal([], gathered_constants)
    end

    it("gathers only classes with Protobuf Module") do
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

      assert_equal(
        ["Cart", "Google::Protobuf::Map", "Google::Protobuf::RepeatedField"],
        gathered_constants
      )
    end
  end

  describe("#decorate") do
    after(:each) do
      T.unsafe(self).assert_no_generated_errors
    end

    it("generates methods in RBI files for classes with Protobuf with integer field type") do
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

          sig { returns(Integer) }
          def customer_id; end

          sig { params(value: Integer).returns(Integer) }
          def customer_id=(value); end

          sig { returns(Integer) }
          def shop_id; end

          sig { params(value: Integer).returns(Integer) }
          def shop_id=(value); end
        end
      RBI

      assert_equal(expected, rbi_for(:Cart))
    end

    it("generates methods in RBI files for classes with Protobuf with string field type") do
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

          sig { returns(String) }
          def events; end

          sig { params(value: String).returns(String) }
          def events=(value); end
        end
      RBI

      assert_equal(expected, rbi_for(:Cart))
    end

    it("generates methods in RBI files for classes with Protobuf with message field type") do
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

          sig { returns(Google::Protobuf::UInt64Value) }
          def cart_item_index; end

          sig { params(value: Google::Protobuf::UInt64Value).returns(Google::Protobuf::UInt64Value) }
          def cart_item_index=(value); end
        end
      RBI

      assert_equal(expected, rbi_for(:Cart))
    end

    it("generates methods in RBI files for classes with Protobuf with enum field") do
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

          sig { returns(Symbol) }
          def value_type; end

          sig { params(value: T.any(Symbol, Integer)).returns(Symbol) }
          def value_type=(value); end
        end
      RBI

      expected_enum_rbi = <<~RBI
        # typed: strong

        module Cart::VALUE_TYPE
          FIXED_AMOUNT = 1
          NULL = 0
          PERCENTAGE = 2
        end
      RBI

      assert_equal(expected_enum_rbi, rbi_for("Cart::VALUE_TYPE"))
      assert_equal(expected, rbi_for(:Cart))
    end

    it("generates methods in RBI files for classes with Protobuf with enum field with defined type") do
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

          sig { returns(Symbol) }
          def value_type; end

          sig { params(value: T.any(Symbol, Integer)).returns(Symbol) }
          def value_type=(value); end
        end
      RBI

      assert_equal(expected, rbi_for(:Cart))
    end

    it("generates methods in RBI files for repeated fields in Protobufs") do
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
          def initialize(customer_ids: Google::Protobuf::RepeatedField.new(:int32), indices: Google::Protobuf::RepeatedField.new(:message, Google::Protobuf::UInt64Value)); end

          sig { returns(Google::Protobuf::RepeatedField[Integer]) }
          def customer_ids; end

          sig { params(value: Google::Protobuf::RepeatedField[Integer]).returns(Google::Protobuf::RepeatedField[Integer]) }
          def customer_ids=(value); end

          sig { returns(Google::Protobuf::RepeatedField[Google::Protobuf::UInt64Value]) }
          def indices; end

          sig { params(value: Google::Protobuf::RepeatedField[Google::Protobuf::UInt64Value]).returns(Google::Protobuf::RepeatedField[Google::Protobuf::UInt64Value]) }
          def indices=(value); end
        end
      RBI

      assert_equal(expected, rbi_for(:Cart))
    end

    it("generates methods in RBI files for map fields in Protobufs") do
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
          def initialize(customers: Google::Protobuf::Map.new(:string, :int32), stores: Google::Protobuf::Map.new(:string, :message, Google::Protobuf::UInt64Value)); end

          sig { returns(Google::Protobuf::Map[String, Integer]) }
          def customers; end

          sig { params(value: Google::Protobuf::Map[String, Integer]).returns(Google::Protobuf::Map[String, Integer]) }
          def customers=(value); end

          sig { returns(Google::Protobuf::Map[String, Google::Protobuf::UInt64Value]) }
          def stores; end

          sig { params(value: Google::Protobuf::Map[String, Google::Protobuf::UInt64Value]).returns(Google::Protobuf::Map[String, Google::Protobuf::UInt64Value]) }
          def stores=(value); end
        end
      RBI

      assert_equal(expected, rbi_for(:Cart))
    end

    it("generates methods in RBI files for classes with Protobuf with all types") do
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
        sig { params(value: T::Boolean).returns(T::Boolean) }
        def bool_value=(value); end
      RBI

      assert_includes(rbi_output, indented(<<~RBI, 2))
        sig { params(value: String).returns(String) }
        def byte_value=(value); end
      RBI

      assert_includes(rbi_output, indented(<<~RBI, 2))
        sig { params(value: Integer).returns(Integer) }
        def customer_id=(value); end
      RBI

      assert_includes(rbi_output, indented(<<~RBI, 2))
        sig { params(value: Integer).returns(Integer) }
        def id=(value); end
      RBI

      assert_includes(rbi_output, indented(<<~RBI, 2))
        sig { params(value: Integer).returns(Integer) }
        def item_id=(value); end
      RBI

      assert_includes(rbi_output, indented(<<~RBI, 2))
        sig { params(value: Float).returns(Float) }
        def money_value=(value); end
      RBI

      assert_includes(rbi_output, indented(<<~RBI, 2))
        sig { params(value: Float).returns(Float) }
        def number_value=(value); end
      RBI

      assert_includes(rbi_output, indented(<<~RBI, 2))
        sig { params(value: Integer).returns(Integer) }
        def shop_id=(value); end
      RBI

      assert_includes(rbi_output, indented(<<~RBI, 2))
        sig { params(value: String).returns(String) }
        def string_value=(value); end
      RBI
    end
  end
end
