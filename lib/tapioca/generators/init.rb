# typed: strict
# frozen_string_literal: true

module Tapioca
  module Generators
    class Init < Base
      sig do
        params(
          sorbet_config: String,
          tapioca_config: String,
          default_postrequire: String,
          default_command: String,
          file_writer: Thor::Actions
        ).void
      end
      def initialize(
        sorbet_config:,
        tapioca_config:,
        default_postrequire:,
        default_command:,
        file_writer: FileWriter.new
      )
        @sorbet_config = sorbet_config
        @tapioca_config = tapioca_config
        @default_postrequire = default_postrequire

        super(default_command: default_command, file_writer: file_writer)

        @installer = T.let(nil, T.nilable(Bundler::Installer))
        @spec = T.let(nil, T.nilable(Bundler::StubSpecification))
      end

      sig { override.void }
      def generate
        create_sorbet_config
        create_tapioca_config
        create_post_require
        create_binstub
      end

      private

      sig { void }
      def create_sorbet_config
        create_file(@sorbet_config, <<~CONTENT, skip: true, force: false)
          --dir
          .
        CONTENT
      end

      sig { void }
      def create_tapioca_config
        create_file(@tapioca_config, <<~YAML, skip: true, force: false)
          gem:
            # Add your `gem` command parameters here:
            #
            # exclude:
            # - gem_name
            # doc: true
            # workers: 5
          dsl:
            # Add your `dsl` command parameters here:
            #
            # exclude:
            # - SomeGeneratorName
            # workers: 5
        YAML
      end

      sig { void }
      def create_post_require
        create_file(@default_postrequire, <<~CONTENT, skip: true, force: false)
          # typed: true
          # frozen_string_literal: true

          # Add your extra requires here (`#{@default_command} require` can be used to boostrap this list)
        CONTENT
      end

      sig { void }
      def create_binstub
        force = File.exist?(@default_command)

        installer.generate_bundler_executable_stubs(spec, { force: force })

        say_status(
          force ? :force : :create,
          @default_command,
          force ? :yellow : :green
        )
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
