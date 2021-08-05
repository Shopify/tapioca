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

        sig { override.params(root: RBI::Tree, constant: T.class_of(::ActiveRecord::Base)).void }
        def decorate(root, constant)
          return if constant.reflections.empty?

          root.create_path(constant) do |scope|
            constant.attachment_reflections.each do |field_name, _value|
              getter_sig = RBI::Sig.new(
                return_type: "T.any(ActiveStorage::Attached::One, ActiveStorage::Atached::Many)"
              )
              scope << RBI::Method.new(field_name, sigs: [getter_sig])
              setter_sig = RBI::Sig.new(params: [RBI::SigParam.new(field_name,
                "T.any(ActiveStorage::Attached::One, ActiveStorage::Attached::Many")])
              scope << RBI::Method.new("#{field_name}=", params: [RBI::Param.new("attachable")], sigs: [setter_sig])
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
