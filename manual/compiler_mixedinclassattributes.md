## MixedInClassAttributes

`Tapioca::Dsl::Compilers::MixedInClassAttributes` generates RBI files for modules that dynamically use
`class_attribute` on classes.

For example, given the following concern

~~~rb
module Taggeable
  extend ActiveSupport::Concern

  included do
    class_attribute :tag
  end
end
~~~

this compiler will produce the RBI file `taggeable.rbi` with the following content:

~~~rbi
# typed: strong

module Taggeable
  include GeneratedInstanceMethods

  mixes_in_class_methods GeneratedClassMethods

  module GeneratedClassMethods
    def tag; end
    def tag=(value); end
    def tag?; end
  end

  module GeneratedInstanceMethods
    def tag; end
    def tag=(value); end
    def tag?; end
  end
end
~~~
