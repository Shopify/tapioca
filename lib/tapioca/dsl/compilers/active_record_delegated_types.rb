# typed: strict
# frozen_string_literal: true

return unless defined?(ActiveRecord::Base)

require "tapioca/dsl/helpers/active_record_column_type_helper"
require "tapioca/dsl/helpers/active_record_constants_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::DelegatedTypes` defines RBI files for subclasses of
      # [`ActiveRecord::Base`](https://api.rubyonrails.org/classes/ActiveRecord/Base.html).
      # This compiler is only responsible for defining the methods that would be created for delegated_types that
      # are defined in the Active Record model.
      #
      # For example, with the following model class:
      #
      # ~~~rb
      # class Entry < ActiveRecord::Base
      #   delegated_type :entryable, types: %w[ Message Comment ]
      # end
      # ~~~
      #
      # this compiler will produce the following methods in the RBI file
      # `entry.rbi`:
      #
      # ~~~rbi
      # # entry.rbi
      # # typed: true
      #
      # class Entry
      #   include GeneratedDelegatedTypeMethods
      #
      #   module GeneratedDelegatedTypeMethods
      #     sig { params(args: T.untyped).returns(T.any(::Message, ::Comment)) }
      #     def build_entryable(*args); end
      #
      #     sig { returns(Class) }
      #     def entryable_class; end
      #
      #     sig { returns(ActiveSupport::StringInquirer) }
      #     def entryable_name; end
      #
      #     sig { returns(T::Boolean) }
      #     def message?; end
      #
      #     sig { returns(T.nilable(::Message)) }
      #     def message; end
      #
      #     sig { returns(T.nilable(Integer)) }
      #     def message_id; end
      #
      #     sig { returns(T::Boolean) }
      #     def comment?; end
      #
      #     sig { returns(T.nilable(::Comment)) }
      #     def comment; end
      #
      #     sig { returns(T.nilable(Integer)) }
      #     def comment_id; end
      #   end
      # end
      #
      # ~~~
      #: [ConstantType = (singleton(ActiveRecord::Base) & Extensions::ActiveRecord)]
      class ActiveRecordDelegatedTypes < Compiler
        include Helpers::ActiveRecordConstantsHelper

        # @override
        #: -> void
        def decorate
          return if constant.__tapioca_delegated_types.nil?

          root.create_path(constant) do |model|
            model.create_module(DelegatedTypesModuleName) do |mod|
              constant.__tapioca_delegated_types.each do |role, data|
                types = data.fetch(:types)
                options = data.fetch(:options, {})
                qualified_types = types.map { |type| qualified_type_name(type, role) }
                populate_role_accessors(mod, role, qualified_types)
                populate_type_helpers(mod, role, types, qualified_types, options)
              end
            end

            model.create_include(DelegatedTypesModuleName)
          end
        end

        class << self
          # @override
          #: -> Enumerable[Module[top]]
          def gather_constants
            descendants_of(::ActiveRecord::Base).reject(&:abstract_class?)
          end
        end

        private

        #: (RBI::Scope mod, Symbol role, Array[String] qualified_types) -> void
        def populate_role_accessors(mod, role, qualified_types)
          mod.create_method(
            "#{role}_name",
            parameters: [],
            return_type: "ActiveSupport::StringInquirer",
          )

          mod.create_method(
            "#{role}_class",
            parameters: [],
            return_type: "T::Class[T.anything]",
          )

          mod.create_method(
            "build_#{role}",
            parameters: [create_rest_param("args", type: "T.untyped")],
            return_type: qualified_types.size == 1 ? qualified_types.first : "T.any(#{qualified_types.join(", ")})",
          )
        end

        #: (RBI::Scope mod, Symbol role, Array[String] types, Array[String] qualified_types, Hash[Symbol, untyped] options) -> void
        def populate_type_helpers(mod, role, types, qualified_types, options)
          types.each_with_index do |type, index|
            populate_type_helper(mod, role, type, qualified_types.fetch(index), options)
          end
        end

        #: (RBI::Scope mod, Symbol role, String type, String qualified_type, Hash[Symbol, untyped] options) -> void
        def populate_type_helper(mod, role, type, qualified_type, options)
          singular   = type.tableize.tr("/", "_").singularize
          query      = "#{singular}?"
          primary_key = options[:primary_key] || "id"
          role_id = options[:foreign_key] || "#{role}_id"

          getter_type, _ = Helpers::ActiveRecordColumnTypeHelper.new(constant).type_for(role_id.to_s)

          mod.create_method(
            query,
            parameters: [],
            return_type: "T::Boolean",
          )

          mod.create_method(
            singular,
            parameters: [],
            return_type: "T.nilable(#{qualified_type})",
          )

          mod.create_method(
            "#{singular}_#{primary_key}",
            parameters: [],
            return_type: as_nilable_type(getter_type),
          )
        end

        # Resolves a delegated type entry to a fully-qualified constant name. The strings passed
        # to `delegated_type(..., types: %w[...])` are written verbatim into the generated RBI,
        # but the surrounding `class A::B::C` scope omits `A` and `A::B` from Sorbet's lexical
        # nesting, so a bare `D` reference fails to resolve to `A::B::D` even when that constant
        # exists. `compute_type` mirrors the namespace-walking lookup ActiveRecord uses for STI
        # and polymorphic associations, so it resolves both bare and fully-qualified names. When
        # the constant can't be resolved we record a compiler error and emit `T.untyped`, which
        # both surfaces the problem and keeps the generated RBI type-checkable.
        #: (String type, Symbol role) -> String
        def qualified_type_name(type, role)
          klass = constant.send(:compute_type, type)
          qualified_name_of(klass) || type
        rescue NameError
          add_error(<<~MSG.strip)
            Cannot generate delegated_type `#{role}` on `#{constant}` since the type `#{type}` does not exist.
          MSG
          "T.untyped"
        end
      end
    end
  end
end
