## Protobuf

`Tapioca::Dsl::Compilers::Protobuf` decorates RBI files for subclasses of
[`Google::Protobuf::MessageExts`](https://github.com/protocolbuffers/protobuf/tree/master/ruby).

For example, with the following "cart.rb" file:

~~~rb
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("cart.proto", :syntax => :proto3) do
    add_message "MyCart" do
      optional :shop_id, :int32, 1
      optional :customer_id, :int64, 2
      optional :number_value, :double, 3
      optional :string_value, :string, 4
    end
  end
end
~~~

this compiler will produce the RBI file `cart.rbi` with the following content:

~~~rbi
# cart.rbi
# typed: strong
class Cart < Google::Protobuf::AbstractMessage
  sig { returns(Integer) }
  def customer_id; end

  sig { params(value: Integer).returns(Integer) }
  def customer_id=(value); end

  sig { returns(Integer) }
  def shop_id; end

  sig { params(value: Integer).returns(Integer) }
  def shop_id=(value); end

  sig { returns(String) }
  def string_value; end

  sig { params(value: String).returns(String) }
  def string_value=(value); end


  sig { returns(Float) }
  def number_value; end

  sig { params(value: Float).returns(Float) }
  def number_value=(value); end
end
~~~

Please note that you might have to ignore the originally generated Protobuf Ruby files
to avoid _Redefining constant_ issues when doing type checking.
Do this by extending your Sorbet config file:

~~~
--ignore=/path/to/proto/cart_pb.rb
~~~
