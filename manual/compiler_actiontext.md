## ActionText

`Tapioca::Dsl::Compilers::ActionText` decorates RBI files for subclasses of
`ActiveRecord::Base` that declare [has_rich_text](https://edgeguides.rubyonrails.org/action_text_overview.html#creating-rich-text-content)

For example, with the following `ActiveRecord::Base` subclass:

~~~rb
class Post < ApplicationRecord
 has_rich_text :body
 has_rich_text :title, encrypted: true
end
~~~

this compiler will produce the RBI file `post.rbi` with the following content:

~~~rbi
# typed: strong

class Post
 sig { returns(ActionText::RichText) }
 def body; end

 sig { params(value: T.nilable(T.any(ActionText::RichText, String))).returns(T.untyped) }
 def body=(value); end

 sig { returns(T::Boolean) }
 def body?; end

 sig { returns(ActionText::EncryptedRichText) }
 def title; end

 sig { params(value: T.nilable(T.any(ActionText::EncryptedRichText, String))).returns(T.untyped) }
 def title=(value); end

 sig { returns(T::Boolean) }
 def title?; end
end
~~~
