# typed: strict
# frozen_string_literal: true

class GitAttributes
  class << self
    extend T::Sig

    sig { params(path: Pathname).void }
    def create_generated_attribute_file(path)
      create_gitattributes_file(path, <<~CONTENT)
        **/*.rbi linguist-generated=true
      CONTENT
    end

    sig { params(path: Pathname).void }
    def create_vendored_attribute_file(path)
      create_gitattributes_file(path, <<~CONTENT)
        **/*.rbi linguist-vendored=true
      CONTENT
    end

    private

    sig { params(path: Pathname, content: String).void }
    def create_gitattributes_file(path, content)
      # We don't want to start creating folders, just to write
      # the `.gitattributes` file. So, if the folder doesn't
      # exist, we just return.
      return unless path.exist?

      File.write(path.join(".gitattributes"), content)
    end
  end
end
