# typed: strict
# frozen_string_literal: true

module Tapioca
  module Generators
    class Init < Base
      sig do
        params(
          sorbet_config: String,
          default_postrequire: String,
          default_command: String
        ).void
      end
      def initialize(sorbet_config:, default_postrequire:, default_command:)
        @sorbet_config = sorbet_config
        @default_postrequire = default_postrequire

        super(default_command: default_command)

        @installer = T.let(nil, T.nilable(Bundler::Installer))
        @spec = T.let(nil, T.nilable(Bundler::StubSpecification))
      end

      sig { override.void }
      def generate
        create_config
        create_post_require
        if File.exist?(@default_command)
          generate_binstub!
        else
          generate_binstub
        end
      end

      private

      sig { void }
      def create_config
        create_file(@sorbet_config, <<~CONTENT, skip: true)
          --dir
          .
        CONTENT
      end

      sig { void }
      def create_post_require
        create_file(@default_postrequire, <<~CONTENT, skip: true)
          # typed: true
          # frozen_string_literal: true

          # Add your extra requires here (`#{@default_command} require` can be used to boostrap this list)
        CONTENT
      end

      sig { void }
      def generate_binstub!
        installer.generate_bundler_executable_stubs(spec, { force: true })
        say_status(:force, @default_command, :yellow)
      end

      sig { void }
      def generate_binstub
        installer.generate_bundler_executable_stubs(spec)
        say_status(:create, @default_command, :green)
      end

      sig { returns(Bundler::Installer) }
      def installer
        @installer ||= Bundler::Installer.new(Bundler.root, Bundler.definition)
      end

      sig { returns(Bundler::StubSpecification) }
      def spec
        @spec ||= Bundler.definition.specs.find { |s| s.name == "tapioca" }
      end
    end
  end
end
