# typed: strict
# frozen_string_literal: true

return unless defined?(Rails) && defined?(ActiveSupport::TestCase) && defined?(ActiveRecord::TestFixtures)

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
      #   sig { params(fixture_name: T.any(String, Symbol), other_fixtures: NilClass).returns(Post) }
      #   sig { params(fixture_name: T.any(String, Symbol), other_fixtures: T.any(String, Symbol))
      #           .returns(T::Array[Post]) }
      #   def posts(fixture_name, *other_fixtures); end
      # end
      # ~~~
      class ActiveRecordFixtures < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(ActiveSupport::TestCase) } }

        sig { override.void }
        def decorate
          method_names = if fixture_loader.respond_to?(:fixture_sets)
            method_names_from_lazy_fixture_loader
          else
            method_names_from_eager_fixture_loader
          end

          return if method_names.empty?

          root.create_path(constant) do |mod|
            method_names.each do |name|
              create_fixture_method(mod, name.to_s)
            end
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            return [] unless defined?(Rails.application) && Rails.application

            [ActiveSupport::TestCase]
          end
        end

        private

        sig { returns(T::Class[ActiveRecord::TestFixtures]) }
        def fixture_loader
          @fixture_loader ||= T.let(
            Class.new do
              T.unsafe(self).include(ActiveRecord::TestFixtures)

              if respond_to?(:fixture_paths=)
                T.unsafe(self).fixture_paths = [Rails.root.join("test", "fixtures")]
              else
                T.unsafe(self).fixture_path = Rails.root.join("test", "fixtures")
              end

              # https://github.com/rails/rails/blob/7c70791470fc517deb7c640bead9f1b47efb5539/activerecord/lib/active_record/test_fixtures.rb#L46
              singleton_class.define_method(:file_fixture_path) do
                Rails.root.join("test", "fixtures", "files")
              end

              T.unsafe(self).fixtures(:all)
            end,
            T.nilable(T::Class[ActiveRecord::TestFixtures]),
          )
        end

        sig { returns(T::Array[String]) }
        def method_names_from_lazy_fixture_loader
          T.unsafe(fixture_loader).fixture_sets.keys
        end

        sig { returns(T::Array[Symbol]) }
        def method_names_from_eager_fixture_loader
          fixture_loader.ancestors # get all ancestors from class that includes AR fixtures
            .drop(1) # drop the anonymous class itself from the array
            .reject(&:name) # only collect anonymous ancestors because fixture methods are always on an anonymous module
            .map! do |mod|
              [mod.private_instance_methods(false), mod.instance_methods(false)]
            end
            .flatten # merge methods into a single list
        end

        sig { params(mod: RBI::Scope, name: String).void }
        def create_fixture_method(mod, name)
          model_class = active_record_models[name] || "T.untyped"
          mod << RBI::Method.new(name) do |node|
            node.add_param("fixture_name")
            node.add_rest_param("other_fixtures")

            node.add_sig do |sig|
              sig.add_param("fixture_name", "T.any(String, Symbol)")
              sig.add_param("other_fixtures", "NilClass")
              sig.return_type = model_class
            end

            node.add_sig do |sig|
              sig.add_param("fixture_name", "T.any(String, Symbol)")
              sig.add_param("other_fixtures", "T.any(String, Symbol)")
              sig.return_type = "T::Array[#{model_class}]"
            end
          end
        end

        sig { returns(T::Hash[String, String]) }
        def active_record_models
          @active_record_models ||= T.let(
            ActiveRecord::Base.descendants.map do |model|
              [fixture_name(model.name), model.name]
            end.to_h,
            T.nilable(T::Hash[String, String]),
          )
        end

        sig { params(class_name: String).returns(String) }
        def fixture_name(class_name)
          singular = class_name.gsub("::", "/")
            .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .tr("-", "_")
            .downcase
            .gsub("/", "_")

          "#{singular}s"
        end
      end
    end
  end
end
