# typed: strict
# frozen_string_literal: true

module Tapioca
  module Generators
    class Require < Base
      sig { void }
      def build_requires
        requires_path = Config::DEFAULT_POSTREQUIRE
        compiler = Compilers::RequiresCompiler.new(Config::SORBET_CONFIG)
        name = set_color(requires_path, :yellow, :bold)
        say("Compiling #{name}, this may take a few seconds... ")

        rb_string = compiler.compile
        if rb_string.empty?
          say("Nothing to do", :green)
          return
        end

        # Clean all existing requires before regenerating the list so we update
        # it with the new one found in the client code and remove the old ones.
        File.delete(requires_path) if File.exist?(requires_path)

        content = String.new
        content << "# typed: true\n"
        content << "# frozen_string_literal: true\n\n"
        content << rb_string

        outdir = File.dirname(requires_path)
        FileUtils.mkdir_p(outdir)
        File.write(requires_path, content)

        say("Done", :green)

        say("All requires from this application have been written to #{name}.", [:green, :bold])
        cmd = set_color("#{Config::DEFAULT_COMMAND} gem", :yellow, :bold)
        say("Please review changes and commit them, then run `#{cmd}`.", [:green, :bold])
      end
    end
  end
end
