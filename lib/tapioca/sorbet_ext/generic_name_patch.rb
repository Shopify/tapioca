# typed: true
# frozen_string_literal: true

require 'tapioca/sorbet_ext/name_patch'

module T
  module Types
    class CustomTypeVariable < T::Types::TypeVariable
      def initialize(type_variable_type, type_variable, fixed, lower, upper)
        parts = []
        parts << ":#{type_variable.variance}" unless type_variable.variance == :invariant
        parts << "fixed: #{fixed}" if fixed
        parts << "lower: #{lower}" unless lower == T.untyped
        parts << "upper: #{upper}" unless upper == BasicObject

        parameters = parts.join(", ")

        @string_format = "#{type_variable_type}(#{parameters})"
      end

      def to_s
        @string_format
      end
    end
  end

  module Generic
    module TypeStoragePatch
      def [](*types)
        # generate the name for this generic type
        type_list = types.join(", ")
        name = Module.instance_method(:name).bind(self).call
        name = "#{name}[#{type_list}]"

        # lookup or create a clone of self with an overridden "name"
        # method that returns the proper name for the concrete
        # generic type that this instance represents.
        __instances[name] ||= T.unsafe(self).clone.tap do |clone|
          clone.define_singleton_method(:name) { name }
        end
      end

      def type_member(variance = :invariant, fixed: nil, lower: T.untyped, upper: BasicObject)
        T::Types::CustomTypeVariable.new(:type_member, super, fixed, lower, upper).tap do |type_variable|
          __type_variables << type_variable
        end
      end

      def type_template(variance = :invariant, fixed: nil, lower: T.untyped, upper: BasicObject)
        T::Types::CustomTypeVariable.new(:type_template, super, fixed, lower, upper).tap do |type_variable|
          __type_variables << type_variable
        end
      end

      def __type_variables
        T::Private::Abstract::Data.set_default(self, "type_variables", [])
      end

      private

      def __instances
        T::Private::Abstract::Data.set_default(self, "generic_instances", {})
      end
    end

    prepend TypeStoragePatch
  end

  module Types
    class Simple
      module GenericNamePatch
        def name
          if T::Generic === @raw_type
            # for types that are generic, use the name
            # returned by the "name" method of this instance
            @name ||= T.unsafe(@raw_type).name.freeze
          else
            # otherwise, fallback to the normal name lookup
            super
          end
        end
      end

      prepend GenericNamePatch
    end
  end
end
