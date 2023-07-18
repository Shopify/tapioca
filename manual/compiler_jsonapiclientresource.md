## JsonApiClientResource

`Tapioca::Dsl::Compilers::JsonApiClientResource` generates RBI files for classes that inherit
[`JsonApiClient::Resource`](https://github.com/JsonApiClient/json_api_client).

For example, with the following classes that inherits `JsonApiClient::Resource`:

~~~rb
# user.rb
class User < JsonApiClient::Resource
  has_many :posts

  property :name, type: :string
  property :is_admin, type: :boolean, default: false
end

# post.rb
class Post < JsonApiClient::Resource
  belongs_to :user

  property :title, type: :string
end
~~~

this compiler will produce RBI files with the following content:

~~~rbi
# user.rbi
# typed: strong

class User
  include JsonApiClientResourceGeneratedMethods

  module JsonApiClientResourceGeneratedMethods
    sig { returns(T::Boolean) }
    def is_admin; end

    sig { params(is_admin: T::Boolean).returns(T::Boolean) }
    def is_admin=(is_admin); end

    sig { returns(T.nilable(::String)) }
    def name; end

    sig { params(name: T.nilable(::String)).returns(T.nilable(::String)) }
    def name=(name); end

    sig { returns(T.nilable(T::Array[Post])) }
    def posts; end

    sig { params(posts: T.nilable(T::Array[Post])).returns(T.nilable(T::Array[Post])) }
    def posts=(posts); end
  end
end

# post.rbi
# typed: strong

class Post
  include JsonApiClientResourceGeneratedMethods

  module JsonApiClientResourceGeneratedMethods
    sig { returns(T.nilable(::String)) }
    def title; end

    sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
    def title=(title); end

    sig { returns(T.nilable(::String)) }
    def user_id; end

    sig { params(user_id: T.nilable(::String)).returns(T.nilable(::String)) }
    def user_id=(user_id); end
  end
end
~~~
