# typed: strict
# frozen_string_literal: true

begin
  require "active_record"
  require "active_storage"
  require "active_storage/attached"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      class ActiveStorage < Base
        extend T::Sig

        ReflectionType = T.type_alias do
          T.any(::ActiveStorage::Reflection::HasOneAttachedReflection,
            ::ActiveStorage::Reflection::HasManyAttachedReflection)
        end

        sig { override.params(root: RBI::Tree, constant: T.class_of(::ActiveRecord::Base)).void }
        def decorate(root, constant)
          return if constant.reflections.empty?

          root.create_path(constant) do |scope|
            constant.attachment_reflections.each do |field_name, _value|
              scope << RBI::Method.new(field_name)
              scope << RBI::Method.new("#{field_name}=")
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          ActiveRecord::Base.descendants.reject(&:abstract_class?)
        end
      end
    end
  end
end
