# typed: strict
# frozen_string_literal: true

module Tapioca
  module Helpers
    module Test
      # @requires_ancestor: Kernel
      module Content
        extend T::Sig
        #: -> void
        def teardown
          super
          remove_tmp_path
        end

        #: (*String args) -> String
        def tmp_path(*args)
          @tmp_path = @tmp_path #: String?
          @tmp_path ||= Dir.mktmpdir
          T.unsafe(File).join(@tmp_path, *args)
        end

        #: -> void
        def remove_tmp_path
          FileUtils.rm_rf(tmp_path)
        end

        #: (String name, String content, ?require_file: bool) -> String
        def add_ruby_file(name, content, require_file: true)
          add_content_file(name, content).tap do |file_name|
            Tapioca.silence_warnings { require(file_name) } if require_file
          end
        end

        #: (String name, String content) -> String
        def add_content_file(name, content)
          file_name = tmp_path("lib/#{name}")
          raise ArgumentError, "a file named '#{name}' was already added; cannot overwrite." if File.exist?(file_name)

          FileUtils.mkdir_p(File.dirname(file_name))
          File.write(file_name, content)
          file_name
        end
      end
    end
  end
end
