# typed: strict
# frozen_string_literal: true

require "spec_with_project"
require "tapioca/compilers/requires_compiler"

module Tapioca
  module Compilers
    class RequiresCompilerSpec < Tapioca::SpecWithProject
      describe RequiresCompiler do
        after do
          @project.remove("lib/")
          @project.remove("test/")
          @project.remove("sorbet/")
        end

        it "does nothing on an empty project" do
          @project.sorbet_config(<<~CONFIG)
            .
          CONFIG

          compiler = Tapioca::Compilers::RequiresCompiler.new(@project.absolute_path("sorbet/config"))
          assert_empty(compiler.compile)
        end

        it "extracts the requires from a simple project" do
          @project.sorbet_config(<<~CONFIG)
            lib/
          CONFIG

          @project.write("lib/simple.rb", <<~RB)
            require "a"
            require "b"
            require ("c")
            require"d"
            require"e"
            require("f")
            require_relative "z"

            if Random.rand > 0.5
              require "g"
              require_relative "z"
            else
              require   ("h")
              require   "i"
              require  "j"
            end
          RB

          compiler = Tapioca::Compilers::RequiresCompiler.new(@project.absolute_path("sorbet/config"))
          assert_equal(<<~REQ, compiler.compile)
            require "a"
            require "b"
            require "c"
            require "d"
            require "e"
            require "f"
            require "g"
            require "h"
            require "i"
            require "j"
          REQ
        end

        it "extracts the requires from all the files listed in the sorbet config" do
          @project.sorbet_config(<<~CONFIG)
            lib/
            test/file1.rb
            test/file2.rb
          CONFIG

          @project.write("lib/file1.rb", <<~RB)
            require "a"
          RB

          @project.write("lib/file2.rb", <<~RB)
            require "b"
          RB

          @project.write("test/file1.rb", <<~RB)
            require "c"
          RB

          @project.write("test/file2.rb", <<~RB)
            require "d"
          RB

          @project.write("test/file3.rb", <<~RB)
            require "e"
          RB

          compiler = Tapioca::Compilers::RequiresCompiler.new(@project.absolute_path("sorbet/config"))
          assert_equal(<<~REQ, compiler.compile)
            require "a"
            require "b"
            require "c"
            require "d"
          REQ
        end

        it "ignores requires with interpolation" do
          @project.sorbet_config(<<~CONFIG)
            .
          CONFIG

          @project.write("lib/file1.rb", <<~'RB')
            require "a"
            require "#{ENV["SOMETHING"]}"
          RB

          @project.write("lib/file2.rb", <<~'RB')
            require "b"
            require "a"
            require "lib-#{1 + 2}"
          RB

          compiler = Tapioca::Compilers::RequiresCompiler.new(@project.absolute_path("sorbet/config"))
          assert_equal(<<~REQ, compiler.compile)
            require "a"
            require "b"
          REQ
        end

        it "ignores files ignored in the sorbet config" do
          @project.sorbet_config(<<~CONFIG)
            .
            --ignore=lib/
            --ignore=test/file3.rb
          CONFIG

          @project.write("lib/file1.rb", <<~RB)
            require "a"
          RB

          @project.write("lib/file2.rb", <<~RB)
            require "b"
          RB

          @project.write("test/file1.rb", <<~RB)
            require "c"
          RB

          @project.write("test/file2.rb", <<~RB)
            require "d"
          RB

          @project.write("test/file3.rb", <<~RB)
            require "e"
          RB

          compiler = Tapioca::Compilers::RequiresCompiler.new(@project.absolute_path("sorbet/config"))
          assert_equal(<<~REQ, compiler.compile)
            require "c"
            require "d"
          REQ
        end

        it "ignores files located in the project" do
          @project.sorbet_config(<<~CONFIG)
            .
          CONFIG

          @project.write("lib/a.rb", <<~RB)
            require "liba"
          RB

          @project.write("lib/b.rb", <<~RB)
            require "libb"
          RB

          @project.write("test/file1.rb", <<~RB)
            require "a"
            require "libc"
          RB

          @project.write("test/file2.rb", <<~RB)
            require "b"
            require "libd"
          RB

          compiler = Tapioca::Compilers::RequiresCompiler.new(@project.absolute_path("sorbet/config"))
          assert_equal(<<~REQ, compiler.compile)
            require "liba"
            require "libb"
            require "libc"
            require "libd"
          REQ
        end

        it "handles ruby source files with encodings other than UTF-8" do
          @project.sorbet_config(<<~CONFIG)
            .
          CONFIG

          @project.write("lib/utf8-ascii-only.rb", <<~RB)
            require "a"
          RB

          @project.write("lib/utf8.rb", <<~RB)
            require "b" # やあ
          RB

          @project.write("lib/win-31j.rb", (<<~RB).encode("Windows-31J"))
            # encoding:Windows-31J

            require "b"
            require "c" # やあ
          RB

          compiler = Tapioca::Compilers::RequiresCompiler.new(@project.absolute_path("sorbet/config"))
          assert_equal(<<~REQ, compiler.compile)
            require "a"
            require "b"
            require "c"
          REQ
        end
      end
    end
  end
end
