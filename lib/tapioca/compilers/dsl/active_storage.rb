# typed: strict
# frozen_string_literal: true

begin
  require "active_record"
  require "active_storage"
  require "active_storage/reflection"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::Dsl::ActiveStorage` decorates RBI files for subclasses of
      # `ActiveRecord::Base` that declare [one](https://edgeguides.rubyonrails.org/active_storage_overview.html#has-one-attached)
      # or [many](https://edgeguides.rubyonrails.org/active_storage_overview.html#has-many-attached) attachments.
      #
      # For example, with the following `ActiveRecord::Base` subclass:
      #
      # ~~~rb
      # class Post < ApplicationRecord
      #  has_one_attached :photo
      #  has_many_attached :blogs
      # end
      # ~~~
      #
      # this generator will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # typed: true
      # class Post
      #  def photo; end
      #  def photo=; end
      #  def blogs; end
      #  def blogs=; end
      # end
      # ~~~
      class ActiveStorage < Base
        extend T::Sig

        sig do
          override.params(root: RBI::Tree,
            constant: ::ActiveStorage::Reflection::ActiveRecordExtensions::ClassMethods).void
        end
        def decorate(root, constant)
          return if constant.reflect_on_all_attachments.empty?

          root.create_path(constant) do |scope|
            constant.reflect_on_all_attachments.each do |reflection|
              type = type_of(reflection)
              name = reflection.name.to_s

              getter_sig = RBI::Sig.new(return_type: type)
              setter_sig = RBI::Sig.new(params: [RBI::SigParam.new("attachable", type)])

              scope << RBI::Method.new(name, sigs: [getter_sig])
              scope << RBI::Method.new("#{name}=", params: [RBI::Param.new("attachable")],
            sigs: [setter_sig])
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          ActiveRecord::Base.descendants
            .reject(&:abstract_class?)
            .grep(::ActiveStorage::Reflection::ActiveRecordExtensions::ClassMethods)
        end

        private

        sig do
          params(reflection: T.any(::ActiveStorage::Reflection::HasOneAttachedReflection,
            ::ActiveStorage::Reflection::HasManyAttachedReflection)).returns(String)
        end
        def type_of(reflection)
          case reflection.macro
          when :has_one_attached
            "ActiveStorage::Attached::One"
          when :has_many_attached
            "ActiveStorage::Attached::Many"
          end
        end
      end
    end
  end
end
