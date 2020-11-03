# typed: true
# frozen_string_literal: true

require 'tapioca/sorbet_ext/name_patch'

module T
  module Generic
    module TypeStoragePatch
      def [](*types)
        name = __type_name(types)

        __instances[name] ||= __create_typed_instance(name)
      end

      def type_member(variance = :invariant, fixed: nil, lower: T.untyped, upper: BasicObject)
        __store_type_variable(super, fixed, lower, upper)
      end

      def type_template(variance = :invariant, fixed: nil, lower: T.untyped, upper: BasicObject)
        __store_type_variable(super, fixed, lower, upper)
      end

      def __type_variables
        T::Private::Abstract::Data.set_default(self, "type_variables", [])
      end

      private

      def __instances
        T::Private::Abstract::Data.set_default(self, "generic_instances", {})
      end

      def __type_name(types)
        type_list = types.join(", ")
        name = Module.instance_method(:name).bind(self).call

        "#{name}[#{type_list}]"
      end

      def __create_typed_instance(name)
        T.unsafe(self).clone.tap do |me|
          me.singleton_class.instance_exec do
            T.unsafe(self).send(:define_method, :name) { name }
          end
        end
      end

      def __store_type_variable(type_variable, fixed, lower, upper)
        type_variable.singleton_class.instance_exec do
          T.unsafe(self).send(:define_method, :fixed) { fixed }
          T.unsafe(self).send(:define_method, :lower) { lower unless lower == T.untyped }
          T.unsafe(self).send(:define_method, :upper) { upper unless upper == BasicObject }
        end
        __type_variables << type_variable
        type_variable
      end
    end

    prepend TypeStoragePatch
  end

  module Types
    class Simple
      module GenericNamePatch
        def name
          return super unless T::Generic === @raw_type
          @name ||= T.unsafe(@raw_type).name.freeze
        end
      end

      prepend GenericNamePatch
    end
  end
end
