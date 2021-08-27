# typed: strict
# frozen_string_literal: true

module Tapioca
  module Generators
    class RequiresGenerator < BaseGenerator
      extend(T::Sig)

      sig { override.void }
      def generate
        build_requires
      end

      sig { override.params(error: String).void }
      def error_handler(error)
      end

      private

      sig { void }
      def build_requires
        requires_path = Config::DEFAULT_POSTREQUIRE
        compiler = Compilers::RequiresCompiler.new(Config::SORBET_CONFIG)

        rb_string = compiler.compile
        return if rb_string.empty?

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
      end
    end
  end
end
