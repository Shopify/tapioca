## MeasuredRails

`Tapioca::Dsl::Compilers::MeasuredRails` refines RBI files for subclasses of
[`ActiveRecord::Base`](https://api.rubyonrails.org/classes/ActiveRecord/Base.html)
that utilize the [`measured-rails`](https://github.com/shopify/measured-rails) DSL.
This compiler is only responsible for defining the methods that would be created
for measured fields that are defined in the Active Record model.

For example, with the following model class:

~~~rb
class Package < ActiveRecord::Base
  measured Measured::Weight, :minimum_weight
  measured Measured::Length, :total_length
  measured Measured::Volume, :total_volume
end
~~~

this compiler will produce the following methods in the RBI file
`package.rbi`:

~~~rbi
# package.rbi
# typed: true

class Package
  include GeneratedMeasuredRailsMethods

  module GeneratedMeasuredRailsMethods
    sig { returns(T.nilable(Measured::Weight)) }
    def minimum_weight; end

    sig { params(value: T.nilable(Measured::Weight)).void }
    def minimum_weight=(value); end

    sig { returns(T.nilable(Measured::Length)) }
    def total_length; end

    sig { params(value: T.nilable(Measured::Length)).void }
    def total_length=(value); end

    sig { returns(T.nilable(Measured::Volume)) }
    def total_volume; end

    sig { params(value: T.nilable(Measured::Volume)).void }
    def total_volume=(value); end
  end
end
~~~
