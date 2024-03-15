# typed: strict
# frozen_string_literal: true

module Tapioca
  module Helpers
    module Test
      module Content
        extend T::Sig
        extend T::Helpers

        requires_ancestor { Kernel }

        sig { void }
        def teardown
          super
          remove_tmp_path
        end

        sig { params(args: String).returns(String) }
        def tmp_path(*args)
          @tmp_path = T.let(@tmp_path, T.nilable(String))
          @tmp_path ||= Dir.mktmpdir
          T.unsafe(File).join(@tmp_path, *args)
        end

        sig { void }
        def remove_tmp_path
          FileUtils.rm_rf(tmp_path)
        end

        sig { params(name: String, content: String, require_file: T::Boolean).returns(String) }
        def add_ruby_file(name, content, require_file: true)
          add_content_file(name, content).tap do |file_name|
            Tapioca.silence_warnings { require(file_name) } if require_file
          end
        end

        sig { params(name: String, content: String).returns(String) }
        def add_content_file(name, content)
          file_name = tmp_path("lib/#{name}")
          raise ArgumentError, "a file named '#{name}' was already added; cannot overwrite." if File.exist?(file_name)

          FileUtils.mkdir_p(File.dirname(file_name))
          File.write(file_name, content)
          file_name
        end

        sig { params(name: String, content: String, require_file: T::Boolean).void }
        def add_proto_file(name, content, require_file: true)
          proto_path = tmp_path("proto/#{name}.proto")
          raise ArgumentError, "a file named '#{name}' was already added; cannot overwrite." if File.exist?(proto_path)

          proto_dir = File.dirname(proto_path)
          FileUtils.mkdir_p(proto_dir)
          File.write(proto_path, content)

          lib_path = tmp_path("lib")
          FileUtils.mkdir_p(lib_path)
          _, stderr, status = Open3.capture3("protoc --proto_path=#{proto_dir} --ruby_out=#{lib_path} #{proto_path}")
          raise "Error executing protoc: #{stderr}" unless status.success?

          Tapioca.silence_warnings { require("#{lib_path}/#{name}_pb.rb") } if require_file
        end
      end
    end
  end
end
