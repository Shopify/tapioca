# typed: strict
# frozen_string_literal: true

module Tapioca
  module Generators
    class Require < Base
      sig do
        params(
          requires_path: String,
          sorbet_config_path: String,
          default_command: String,
          file_writer: Thor::Actions
        ).void
      end
      def initialize(requires_path:, sorbet_config_path:, default_command:, file_writer: FileWriter.new)
        @requires_path = requires_path
        @sorbet_config_path = sorbet_config_path

        super(default_command: default_command, file_writer: file_writer)
      end

      sig { override.void }
      def generate
        compiler = Compilers::RequiresCompiler.new(@sorbet_config_path)
        name = set_color(@requires_path, :yellow, :bold)
        say("Compiling #{name}, this may take a few seconds... ")

        rb_string = compiler.compile
        if rb_string.empty?
          say("Nothing to do", :green)
          return
        end

        # Clean all existing requires before regenerating the list so we update
        # it with the new one found in the client code and remove the old ones.
        File.delete(@requires_path) if File.exist?(@requires_path)

        content = +"# typed: true\n"
        content << "# frozen_string_literal: true\n\n"
        content << rb_string

        outdir = File.dirname(@requires_path)
        FileUtils.mkdir_p(outdir)
        File.write(@requires_path, content)

        say("Done", :green)

        say("All requires from this application have been written to #{name}.", [:green, :bold])
        cmd = set_color("#{@default_command} gem", :yellow, :bold)
        say("Please review changes and commit them, then run `#{cmd}`.", [:green, :bold])
      end
    end
  end
end
