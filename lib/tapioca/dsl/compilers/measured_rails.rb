# typed: strict
# frozen_string_literal: true

begin
  require "rails"
  require "measured-rails"
rescue LoadError
  return
end

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::MeasuredRails` refines RBI files for subclasses of
      # [`ActiveRecord::Base`](https://api.rubyonrails.org/classes/ActiveRecord/Base.html)
      # that utilize the [`measured-rails`](https://github.com/shopify/measured-rails) DSL.
      # This compiler is only responsible for defining the methods that would be created
      # for measured fields that are defined in the Active Record model.
      #
      # For example, with the following model class:
      #
      # ~~~rb
      # class Package < ActiveRecord::Base
      #   measured Measured::Weight, :minimum_weight
      #   measured Measured::Length, :total_length
      #   measured Measured::Volume, :total_volume
      # end
      # ~~~
      #
      # this compiler will produce the following methods in the RBI file
      # `package.rbi`:
      #
      # ~~~rbi
      # # package.rbi
      # # typed: true
      #
      # class Package
      #   include GeneratedMeasuredRailsMethods
      #
      #   module GeneratedMeasuredRailsMethods
      #     sig { returns(T.nilable(Measured::Weight)) }
      #     def minimum_weight; end
      #
      #     sig { params(value: T.nilable(Measured::Weight)).void }
      #     def minimum_weight=(value); end
      #
      #     sig { returns(T.nilable(Measured::Length)) }
      #     def total_length; end
      #
      #     sig { params(value: T.nilable(Measured::Length)).void }
      #     def total_length=(value); end
      #
      #     sig { returns(T.nilable(Measured::Volume)) }
      #     def total_volume; end
      #
      #     sig { params(value: T.nilable(Measured::Volume)).void }
      #     def total_volume=(value); end
      #   end
      # end
      # ~~~
      class MeasuredRails < Compiler
        extend T::Sig

        ConstantType = type_member(fixed:
          T.all(
            T.class_of(::ActiveRecord::Base),
            ::Measured::Rails::ActiveRecord::ClassMethods
          ))

        MeasuredMethodsModuleName = T.let("GeneratedMeasuredRailsMethods", String)

        sig { override.void }
        def decorate
          return if constant.measured_fields.empty?

          root.create_path(constant) do |model|
            model.create_module(MeasuredMethodsModuleName) do |mod|
              populate_measured_methods(mod)
            end

            model.create_include(MeasuredMethodsModuleName)
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def self.gather_constants
          descendants_of(::ActiveRecord::Base)
        end

        private

        sig { params(model: RBI::Scope).void }
        def populate_measured_methods(model)
          constant.measured_fields.each do |field, attrs|
            klass = attrs[:class].to_s

            model.create_method(
              field.to_s,
              return_type: as_nilable_type(klass)
            )

            model.create_method(
              "#{field}=",
              parameters: [create_param("value", type: as_nilable_type(klass))],
              return_type: "void"
            )
          end
        end
      end
    end
  end
end
