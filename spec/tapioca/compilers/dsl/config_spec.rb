# typed: true
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ConfigSpec < DslSpec
  before(:each) do
    Object.send(:remove_const, :Rails)
  end

  describe("#gather_constants") do
    it("gathers `Settings` if there are no special config constant set") do
      ::Config.load_and_set_settings("")

      assert_equal(["SettingsConfigOptions"], gathered_constants)
    end

    it("gathers `Foo` if there is special config constant set") do
      ::Config.const_name = :Foo
      ::Config.load_and_set_settings("")

      assert_equal(["FooConfigOptions"], gathered_constants)
    end
  end

  describe("#decorate") do
    it("generates a module definition for a simple config") do
      add_content_file("settings.yml", <<~YAML)
        github_key: 12345
        slack_token: foo_bar
      YAML

      add_ruby_file("config.rb", <<~RUBY)
        ::Config.load_and_set_settings(__dir__ + "/settings.yml")
      RUBY

      expected = <<~RBI
        # typed: strong

        Settings = T.let(T.unsafe(nil), SettingsConfigOptions)

        class SettingsConfigOptions < ::Config::Options
          extend T::Generic

          Elem = type_member(fixed: T.untyped)

          sig { returns(T.untyped) }
          def github_key; end

          sig { params(value: T.untyped).returns(T.untyped) }
          def github_key=(value); end

          sig { returns(T.untyped) }
          def slack_token; end

          sig { params(value: T.untyped).returns(T.untyped) }
          def slack_token=(value); end
        end
      RBI

      assert_equal(expected, rbi_for(:SettingsConfigOptions))
    end

    it("generates a module definition for custom config") do
      add_content_file("settings.yml", <<~YAML)
        github_key: 12345
        slack_token: foo_bar
      YAML

      add_ruby_file("config.rb", <<~RUBY)
        ::Config.const_name = :Foo
        ::Config.load_and_set_settings(__dir__ + "/settings.yml")
      RUBY

      expected = <<~RBI
        # typed: strong

        Foo = T.let(T.unsafe(nil), FooConfigOptions)

        class FooConfigOptions < ::Config::Options
          extend T::Generic

          Elem = type_member(fixed: T.untyped)

          sig { returns(T.untyped) }
          def github_key; end

          sig { params(value: T.untyped).returns(T.untyped) }
          def github_key=(value); end

          sig { returns(T.untyped) }
          def slack_token; end

          sig { params(value: T.untyped).returns(T.untyped) }
          def slack_token=(value); end
        end
      RBI

      assert_equal(expected, rbi_for(:FooConfigOptions))
    end

    it("generates a module definition for a nested config") do
      add_content_file("settings.yml", <<~YAML)
        github:
          key: 12345
          client_id: 54321
        slack:
          token: foo_bar
          user_name: quux
      YAML

      add_ruby_file("config.rb", <<~RUBY)
        ::Config.load_and_set_settings(__dir__ + "/settings.yml")
      RUBY

      expected = <<~RBI
        # typed: strong

        Settings = T.let(T.unsafe(nil), SettingsConfigOptions)

        class SettingsConfigOptions < ::Config::Options
          extend T::Generic

          Elem = type_member(fixed: T.untyped)

          sig { returns(T.untyped) }
          def github; end

          sig { params(value: T.untyped).returns(T.untyped) }
          def github=(value); end

          sig { returns(T.untyped) }
          def slack; end

          sig { params(value: T.untyped).returns(T.untyped) }
          def slack=(value); end
        end
      RBI

      assert_equal(expected, rbi_for(:SettingsConfigOptions))
    end
  end
end
