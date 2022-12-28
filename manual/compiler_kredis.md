## Kredis

`Tapioca::Dsl::Compilers::Kredis` decorates RBI files for all
classes that include [`Kredis::Attributes`](https://github.com/rails/kredis/blob/main/lib/kredis/attributes.rb).

For example, with the following class:

~~~rb
class Person < ApplicationRecord
  kredis_list :names
  kredis_flag :awesome
  kredis_counter :steps, expires_in: 1.hour
  kredis_enum :morning, values: %w[ bright blue black ], default: "bright"
end
~~~

this compiler will produce an RBI file with the following content:
~~~rbi
# typed: true

class Person
  module GeneratedKredisAttributeMethods
    sig { returns(Kredis::Types::Flag) }
    def awesome; end

    sig { returns(T::Boolean) }
    def awesome?; end

    sig { returns(PrivateEnumMorning) }
    def morning; end

    sig { returns(Kredis::Types::List) }
    def names; end

    sig { returns(Kredis::Types::Counter) }
    def steps; end

    class PrivateEnumMorning < Kredis::Types::Enum
      sig { void }
      def black!; end

      sig { returns(T::Boolean) }
      def black?; end

      sig { void }
      def blue!; end

      sig { returns(T::Boolean) }
      def blue?; end

      sig { void }
      def bright!; end

      sig { returns(T::Boolean) }
      def bright?; end
    end
  end
end
~~~
