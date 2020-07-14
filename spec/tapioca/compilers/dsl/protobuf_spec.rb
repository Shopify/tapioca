# typed: false
# frozen_string_literal: true

require "spec_helper"

describe("Tapioca::Compilers::Dsl::Protobuf") do
  before(:each) do
    require "tapioca/compilers/dsl/protobuf"
  end

  subject do
    Tapioca::Compilers::Dsl::Protobuf.new
  end

  describe("#gather_constants") do
    def constants_from(content)
      with_content(content) do
        subject.processable_constants.map(&:to_s).sort
      end
    end

    it("gathers no constants if there are no Google::Protobuf classes") do
      content = <<~RUBY
        Google::Protobuf::DescriptorPool.generated_pool.build do
        end
      RUBY

      assert_equal([], constants_from(content))
    end

    it("gathers only classes with Protobuf Module") do
      content = <<~RUBY
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

      assert_equal(["Cart"], constants_from(content))
    end
  end

  describe("#decorate") do
    def rbi_for(content)
      with_content(content) do
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        subject.decorate(parlour.root, Cart)
        parlour.rbi
      end
    end

    it("generates methods in RBI files for classes with Protobuf with integer field type") do
      content = <<~RUBY
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

      expected = <<~RUBY
        # typed: strong
        class Cart
          sig { returns(Integer) }
          def customer_id; end

          sig { params(value: Integer).returns(Integer) }
          def customer_id=(value); end

          sig { returns(Integer) }
          def shop_id; end

          sig { params(value: Integer).returns(Integer) }
          def shop_id=(value); end
        end
      RUBY

      assert_equal(expected, rbi_for(content))
    end

    it("generates methods in RBI files for classes with Protobuf with string field type") do
      content = <<~RUBY
        Google::Protobuf::DescriptorPool.generated_pool.build do
          add_file("cart.proto", :syntax => :proto3) do
            add_message "MyCart" do
              optional :events, :string, 1
            end
          end
        end

        Cart = Google::Protobuf::DescriptorPool.generated_pool.lookup("MyCart").msgclass
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Cart
          sig { returns(String) }
          def events; end

          sig { params(value: String).returns(String) }
          def events=(value); end
        end
      RUBY

      assert_equal(expected, rbi_for(content))
    end

    it("generates methods in RBI files for classes with Protobuf with message field type") do
      content = <<~RUBY
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

      expected = <<~RUBY
        # typed: strong
        class Cart
          sig { returns(Google::Protobuf::UInt64Value) }
          def cart_item_index; end

          sig { params(value: Google::Protobuf::UInt64Value).returns(Google::Protobuf::UInt64Value) }
          def cart_item_index=(value); end
        end
      RUBY

      assert_equal(expected, rbi_for(content))
    end

    it("generates methods in RBI files for classes with Protobuf with enum field") do
      content = <<~RUBY
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

      expected = <<~RUBY
        # typed: strong
        class Cart
          sig { returns(Cart::VALUE_TYPE) }
          def value_type; end

          sig { params(value: Cart::VALUE_TYPE).returns(Cart::VALUE_TYPE) }
          def value_type=(value); end
        end
      RUBY

      assert_equal(expected, rbi_for(content))
    end

    it("generates methods in RBI files for classes with Protobuf with enum field with defined type") do
      content = <<~RUBY
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

      expected = <<~RUBY
        # typed: strong
        class Cart
          sig { returns(Cart::MYVALUETYPE) }
          def value_type; end

          sig { params(value: Cart::MYVALUETYPE).returns(Cart::MYVALUETYPE) }
          def value_type=(value); end
        end
      RUBY

      assert_equal(expected, rbi_for(content))
    end

    it("generates methods in RBI files for classes with Protobuf with all types") do
      content = <<~RUBY
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

      rbi_output = rbi_for(content)

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: T::Boolean).returns(T::Boolean) }
        def bool_value=(value); end
      RUBY

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: String).returns(String) }
        def byte_value=(value); end
      RUBY

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: Integer).returns(Integer) }
        def customer_id=(value); end
      RUBY

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: Integer).returns(Integer) }
        def id=(value); end
      RUBY

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: Integer).returns(Integer) }
        def item_id=(value); end
      RUBY

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: Float).returns(Float) }
        def money_value=(value); end
      RUBY

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: Float).returns(Float) }
        def number_value=(value); end
      RUBY

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: Integer).returns(Integer) }
        def shop_id=(value); end
      RUBY

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: String).returns(String) }
        def string_value=(value); end
      RUBY
    end
  end
end
