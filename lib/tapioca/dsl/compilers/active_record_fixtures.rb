# typed: strict
# frozen_string_literal: true

begin
  require "rails"
  require "active_record"
  require "active_record/fixtures"
  require "active_support/test_case"
rescue LoadError
  return
end

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActiveRecordFixtures` decorates RBIs for test fixture methods
      # that are created dynamically by Rails.
      #
      # For example, given an application with a posts table, we can have a fixture file
      #
      # ~~~yaml
      # first_post:
      #   author: John
      #   title: My post
      # ~~~
      #
      # Rails will allow us to invoke `posts(:first_post)` in tests to get the fixture record.
      # The generated RBI by this compiler will produce the following
      #
      # ~~~rbi
      # # test_case.rbi
      # # typed: true
      # class ActiveSupport::TestCase
      #   sig { params(fixture_names: Symbol).returns(T.untyped) }
      #   def posts(*fixture_names); end
      # end
      # ~~~
      class ActiveRecordFixtures < Compiler
        extend T::Sig

        sig { override.params(root: RBI::Tree, constant: T.class_of(ActiveSupport::TestCase)).void }
        def decorate(root, constant)
          method_names = fixture_loader.ancestors # get all ancestors from class that includes AR fixtures
            .drop(1) # drop the anonymous class itself from the array
            .reject(&:name) # only collect anonymous ancestors because fixture methods are always on an anonymous module
            .map! do |mod|
              [mod.private_instance_methods(false), mod.instance_methods(false)]
            end
            .flatten # merge methods into a single list
          return if method_names.empty?

          root.create_path(constant) do |mod|
            method_names.each do |name|
              create_fixture_method(mod, name.to_s)
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          [ActiveSupport::TestCase]
        end

        private

        sig { returns(Class) }
        def fixture_loader
          Class.new do
            T.unsafe(self).include(ActiveRecord::TestFixtures)
            T.unsafe(self).fixture_path = Rails.root.join("test", "fixtures")
            T.unsafe(self).fixtures(:all)
          end
        end

        sig { params(mod: RBI::Scope, name: String).void }
        def create_fixture_method(mod, name)
          mod.create_method(
            name,
            parameters: [create_rest_param("fixture_names", type: "Symbol")],
            return_type: "T.untyped"
          )
        end
      end
    end
  end
end
