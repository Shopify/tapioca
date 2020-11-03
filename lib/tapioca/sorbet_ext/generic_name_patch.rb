# typed: false
# frozen_string_literal: true

require 'tapioca/sorbet_ext/name_patch'

module T
  module Generic
    module TypeStoragePatch
      def [](*types)
        instances = T::Private::Abstract::Data.set_default(self, "generic_instances", {})
        instance_key = types.join(", ")
        name = "#{Module.instance_method(:name).bind(self).call}[#{instance_key}]"

        return instances[instance_key] if instances.key?(instance_key)

        singleton_class.prepend(Module.new { define_method(:name) { name } })
        instances[instance_key] = self
      end

      def type_member(variance = :invariant, fixed: nil, lower: T.untyped, upper: BasicObject)
        super.tap do |type_member|
          type_member.singleton_class.instance_exec do
            define_method(:fixed) { fixed }
            define_method(:lower) { lower unless lower == T.untyped }
            define_method(:upper) { upper unless upper == BasicObject }
          end
        end
      end

      def type_template(variance = :invariant, fixed: nil, lower: T.untyped, upper: BasicObject)
        super.tap do |type_template|
          type_template.singleton_class.instance_exec do
            define_method(:fixed) { fixed }
            define_method(:lower) { lower unless lower == T.untyped }
            define_method(:upper) { upper unless upper == BasicObject }
          end
        end
      end
    end

    prepend TypeStoragePatch
  end

  module Types
    class Simple
      module GenericNamePatch
        def name
          return super unless T::Generic === @raw_type
          @name ||= @raw_type.name.freeze
        end
      end

      prepend GenericNamePatch
    end
  end
end
