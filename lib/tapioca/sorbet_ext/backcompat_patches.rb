# typed: true
# frozen_string_literal: true

unless defined?(T.anything)
  module T
    module Types
      # The top type
      class Anything < Base
        def initialize
          super
        end

        # overrides Base
        def name
          "T.anything"
        end

        # overrides Base
        def valid?(obj)
          true
        end

        # overrides Base
        private def subtype_of_single?(other)
          case other
          when T::Types::Anything then true
          else false
          end
        end

        module Private
          INSTANCE = Anything.new.freeze
        end
      end
    end

    class << self
      def anything
        T::Types::Anything::Private::INSTANCE
      end
    end
  end
end

unless defined?(T::Class)
  module T
    module Types
      class TypedClass < T::Types::Base
        attr_reader :type

        def initialize(type)
          super
          @type = T::Utils.coerce(type)
        end

        # overrides Base
        def name
          "T::Class[#{@type.name}]"
        end

        def underlying_class
          ::Class
        end

        # overrides Base
        def valid?(obj)
          ::Class.===(obj)
        end

        # overrides Base
        private def subtype_of_single?(type)
          case type
          when TypedClass
            # treat like generics are erased
            true
          when Simple
            ::Class <= type.raw_type
          else
            false
          end
        end

        module Private
          module Pool
            CACHE_FROZEN_OBJECTS =
              begin
                ObjectSpace::WeakMap.new[1] = 1
                true # Ruby 2.7 and newer
              rescue ArgumentError
                false # Ruby 2.6 and older
              end

            @cache = ObjectSpace::WeakMap.new

            class << self
              def type_for_module(mod)
                cached = @cache[mod]
                return cached if cached

                type = TypedClass.new(mod)

                if CACHE_FROZEN_OBJECTS || (!mod.frozen? && !type.frozen?)
                  @cache[mod] = type
                end
                type
              end
            end
          end
        end

        class Untyped < TypedClass
          def initialize
            super(T.untyped)
          end

          module Private
            INSTANCE = Untyped.new.freeze
          end
        end

        class Anything < TypedClass
          def initialize
            super(T.anything)
          end

          module Private
            INSTANCE = Anything.new.freeze
          end
        end
      end
    end

    module Class
      class << self
        def [](type)
          if type.is_a?(T::Types::Untyped)
            T::Types::TypedClass::Untyped::Private::INSTANCE
          elsif type.is_a?(T::Types::Anything)
            T::Types::TypedClass::Anything::Private::INSTANCE
          else
            T::Types::TypedClass::Private::Pool.type_for_module(type)
          end
        end
      end
    end
  end
end
