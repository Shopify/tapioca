# frozen_string_literal: true

module ContentHelper
  def with_contents(contents, requires: [contents.keys.first], &block)
    Dir.mktmpdir do |path|
      dir = Pathname.new(path)
      # Create a "lib" folder
      Dir.mkdir(dir.join("lib"))

      contents.each do |file, content|
        # Add our contents into their files in lib folder
        File.write(dir.join("lib/#{file}"), content)
      end

      Tapioca.silence_warnings do
        # Require files
        requires.each do |file|
          require(dir.join("lib/#{file}"))
        end

        block.call(dir)
      end
    end
  end

  def with_content(content, &block)
    with_contents({ "file.rb" => content }, &block)
  end
end
