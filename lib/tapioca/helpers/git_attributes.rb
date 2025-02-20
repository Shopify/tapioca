# typed: strict
# frozen_string_literal: true

class GitAttributes
  class << self
    extend T::Sig

    #: (Pathname path) -> void
    def create_generated_attribute_file(path)
      create_gitattributes_file(path, <<~CONTENT)
        **/*.rbi linguist-generated=true
      CONTENT
    end

    #: (Pathname path) -> void
    def create_vendored_attribute_file(path)
      create_gitattributes_file(path, <<~CONTENT)
        **/*.rbi linguist-vendored=true
      CONTENT
    end

    private

    #: (Pathname path, String content) -> void
    def create_gitattributes_file(path, content)
      # We don't want to start creating folders, just to write
      # the `.gitattributes` file. So, if the folder doesn't
      # exist, we just return.
      return unless path.exist?

      git_attributes_path = path.join(".gitattributes")
      File.write(git_attributes_path, content) unless git_attributes_path.exist?
    end
  end
end
