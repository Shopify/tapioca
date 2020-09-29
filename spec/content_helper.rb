# typed: strict
# frozen_string_literal: true

module ContentHelper
  extend T::Sig

  sig do
    type_parameters(:Result)
      .params(
        contents: T::Hash[String, String],
        block: T.proc.params(dir: Pathname).returns(T.type_parameter(:Result))
      )
      .returns(T.type_parameter(:Result))
  end
  def with_contents(contents, &block)
    Dir.mktmpdir do |path|
      dir = Pathname.new(path)
      # Create a "lib" folder
      Dir.mkdir(dir.join("lib").to_s)

      contents.each do |file, content|
        # Add our contents into their files in lib folder
        File.write(dir.join("lib/#{file}"), content)
      end

      Tapioca.silence_warnings do
        # Require Ruby files
        contents.keys
          .select { |k| k.end_with?(".rb") }
          .each do |file|
            Kernel.require(dir.join("lib/#{file}").to_s)
          end

        block.call(dir)
      end
    end
  end
end
