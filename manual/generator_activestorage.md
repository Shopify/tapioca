## ActiveStorage

`Tapioca::Compilers::Dsl::ActiveStorage` decorates RBI files for subclasses of
`ActiveRecord::Base` that declare [one](https://edgeguides.rubyonrails.org/active_storage_overview.html#has-one-attached)
or [many](https://edgeguides.rubyonrails.org/active_storage_overview.html#has-many-attached) attachments.

For example, with the following `ActiveRecord::Base` subclass:

~~~rb
class Post < ApplicationRecord
 has_one_attached :photo
 has_many_attached :blogs
end
~~~

this generator will produce the RBI file `post.rbi` with the following content:

~~~rbi
# typed: true
class Post
 def photo; end
 def photo=; end
 def blogs; end
 def blogs=; end
end
~~~
