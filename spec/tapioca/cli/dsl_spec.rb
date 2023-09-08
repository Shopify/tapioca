# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  class DslSpec < SpecWithProject
    describe "cli::dsl" do
      before(:all) do
        @project.write!("config/application.rb", <<~RB)
          require "bundler/setup"
          Bundler.require

          module Rails
            class Application
              attr_reader :config

              def load_tasks; end
            end

            def self.application
              Application.new
            end
          end

          lib_dir = File.expand_path("../lib/", __dir__)

          # Add lib directory to load path
          $LOAD_PATH << lib_dir

          # Require files from lib directory
          Dir.glob("**/*.rb", base: lib_dir).sort.each do |file|
            require(file)
          end
        RB

        @project.write!("config/environment.rb", <<~RB)
          require_relative "application.rb"
        RB
      end

      it "shows an error message for unknown options" do
        @project.bundle_install!
        result = @project.tapioca("dsl --unknown-option")

        assert_empty_stdout(result)

        assert_equal(<<~ERR, result.err)
          Unknown switches "--unknown-option"
        ERR

        refute_success_status(result)
      end

      describe "generate" do
        before(:all) do
          @project.require_real_gem("smart_properties", "1.15.0")
          @project.require_real_gem("sidekiq", "6.2.1")
          @project.bundle_install!
          @gemfile = @project.read("Gemfile")
          @gemfile_lock = @project.read("Gemfile.lock")
        end

        before do
          @project.write!("Gemfile", @gemfile)
          @project.write!("Gemfile.lock", @gemfile_lock)
        end

        after do
          @project.remove!("db")
          @project.remove!("lib")
          @project.remove!("sorbet/rbi/dsl")
        end

        it "must generate a .gitattributes file in the output folder" do
          @project.write("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          result = @project.tapioca("dsl Post --outdir output")

          assert_empty_stderr(result)
          assert_success_status(result)

          assert_project_file_equal("output/.gitattributes", <<~CONTENT)
            **/*.rbi linguist-generated=true
          CONTENT
        ensure
          @project.remove("output")
        end

        it "must not generate a .gitattributes file if the output folder is not created" do
          result = @project.tapioca("dsl --outdir output")

          assert_equal(<<~ERR, result.err)
            No classes/modules can be matched for RBI generation.
            Please check that the requested classes/modules include processable DSL methods.
          ERR
          refute_project_file_exist("output/.gitattributes")
        ensure
          @project.remove("output")
        end

        it "respects the Gemfile and Gemfile.lock" do
          gem = mock_gem("foo", "1.0.0") do
            write!("lib/foo.rb", <<~RB)
              raise "This gem should not have been loaded"

              module Foo
              end
            RB
          end

          @project.require_mock_gem(gem, require: false)

          result = @project.tapioca("dsl")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

          OUT

          assert_equal(<<~ERR, result.err)
            No classes/modules can be matched for RBI generation.
            Please check that the requested classes/modules include processable DSL methods.
          ERR

          refute_success_status(result)
        end

        it "does not generate anything if there are no matching constants" do
          @project.write!("lib/user.rb", <<~RB)
            class User; end
          RB

          result = @project.tapioca("dsl User")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

          OUT

          assert_equal(<<~ERR, result.err)
            No classes/modules can be matched for RBI generation.
            Please check that the requested classes/modules include processable DSL methods.
          ERR

          refute_project_file_exist("sorbet/rbi/dsl/user.rbi")

          refute_success_status(result)
        end

        it "generates RBI files for only required constants" do
          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          result = @project.tapioca("dsl Post")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

                  create  sorbet/rbi/dsl/post.rbi

            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_empty_stderr(result)

          assert_project_file_equal("sorbet/rbi/dsl/post.rbi", <<~RBI)
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for dynamic methods in `Post`.
            # Please instead update this file by running `bin/tapioca dsl Post`.

            class Post
              include SmartPropertiesGeneratedMethods

              module SmartPropertiesGeneratedMethods
                sig { returns(T.nilable(::String)) }
                def title; end

                sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
                def title=(title); end
              end
            end
          RBI

          assert_success_status(result)
        end

        it "errors for unprocessable required constants" do
          result = @project.tapioca("dsl NonExistent::Foo NonExistent::Bar NonExistent::Baz")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

            Error: Cannot find constant 'NonExistent::Foo'
            Error: Cannot find constant 'NonExistent::Bar'
            Error: Cannot find constant 'NonExistent::Baz'
          OUT

          assert_equal("\n", result.err)

          refute_project_file_exist("sorbet/rbi/dsl/non_existent/foo.rbi")
          refute_project_file_exist("sorbet/rbi/dsl/non_existent/bar.rbi")
          refute_project_file_exist("sorbet/rbi/dsl/non_existent/baz.rbi")

          refute_success_status(result)
        end

        it "removes RBI files for unprocessable required constants" do
          @project.write!("sorbet/rbi/dsl/non_existent/foo.rbi")
          @project.write!("sorbet/rbi/dsl/non_existent/baz.rbi")

          result = @project.tapioca("dsl NonExistent::Foo NonExistent::Bar NonExistent::Baz")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

            Error: Cannot find constant 'NonExistent::Foo'
                  remove  sorbet/rbi/dsl/non_existent/foo.rbi
            Error: Cannot find constant 'NonExistent::Bar'
            Error: Cannot find constant 'NonExistent::Baz'
                  remove  sorbet/rbi/dsl/non_existent/baz.rbi
          OUT

          assert_equal("\n", result.err)

          refute_project_file_exist("sorbet/rbi/dsl/non_existent/foo.rbi")
          refute_project_file_exist("sorbet/rbi/dsl/non_existent/baz.rbi")

          refute_success_status(result)
        end

        it "generates RBI files for all processable constants" do
          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          @project.write!("lib/comment.rb", <<~RB)
            require "smart_properties"

            module Namespace
              class Comment
                include SmartProperties
                property! :body, accepts: String
              end
            end
          RB

          result = @project.tapioca("dsl")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

                  create  sorbet/rbi/dsl/namespace/comment.rbi
                  create  sorbet/rbi/dsl/post.rbi

            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_empty_stderr(result)

          assert_project_file_equal("sorbet/rbi/dsl/post.rbi", <<~RBI)
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for dynamic methods in `Post`.
            # Please instead update this file by running `bin/tapioca dsl Post`.

            class Post
              include SmartPropertiesGeneratedMethods

              module SmartPropertiesGeneratedMethods
                sig { returns(T.nilable(::String)) }
                def title; end

                sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
                def title=(title); end
              end
            end
          RBI

          assert_project_file_equal("sorbet/rbi/dsl/namespace/comment.rbi", <<~RBI)
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for dynamic methods in `Namespace::Comment`.
            # Please instead update this file by running `bin/tapioca dsl Namespace::Comment`.

            class Namespace::Comment
              include SmartPropertiesGeneratedMethods

              module SmartPropertiesGeneratedMethods
                sig { returns(::String) }
                def body; end

                sig { params(body: ::String).returns(::String) }
                def body=(body); end
              end
            end
          RBI

          assert_success_status(result)
        end

        it "generates RBI files for processable constants coming from gems" do
          gem = mock_gem("foo", "1.0.0") do
            write!("lib/foo/role.rb", <<~RB)
              require "smart_properties"

              module Foo
                class Role
                  include SmartProperties
                  property :title, accepts: String
                end
              end
            RB
          end

          @project.write!("lib/post.rb", <<~RB)
            require "foo/role"
          RB

          @project.require_mock_gem(gem)
          @project.bundle_install!

          result = @project.tapioca("dsl")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

                  create  sorbet/rbi/dsl/foo/role.rbi

            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_empty_stderr(result)

          assert_project_file_equal("sorbet/rbi/dsl/foo/role.rbi", <<~RBI)
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for dynamic methods in `Foo::Role`.
            # Please instead update this file by running `bin/tapioca dsl Foo::Role`.

            class Foo::Role
              include SmartPropertiesGeneratedMethods

              module SmartPropertiesGeneratedMethods
                sig { returns(T.nilable(::String)) }
                def title; end

                sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
                def title=(title); end
              end
            end
          RBI

          assert_success_status(result)
        end

        it "generates RBI files for engine when provided with an `app_root` flag" do
          @project.write!("test/dummy/lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          @project.write!("test/dummy/lib/comment.rb", <<~RB)
            require "smart_properties"

            module Namespace
              class Comment
                include SmartProperties
                property! :body, accepts: String
              end
            end
          RB

          engine_path = @project.absolute_path + "/test/dummy"

          begin
            FileUtils.mkdir_p(engine_path)
            FileUtils.mv(@project.absolute_path + "/config", engine_path)

            result = @project.tapioca("dsl --app_root=test/dummy")

            assert_empty_stderr(result)

            assert_project_file_equal("sorbet/rbi/dsl/post.rbi", <<~RBI)
              # typed: true

              # DO NOT EDIT MANUALLY
              # This is an autogenerated file for dynamic methods in `Post`.
              # Please instead update this file by running `bin/tapioca dsl Post`.

              class Post
                include SmartPropertiesGeneratedMethods

                module SmartPropertiesGeneratedMethods
                  sig { returns(T.nilable(::String)) }
                  def title; end

                  sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
                  def title=(title); end
                end
              end
            RBI

          # Restore directory structure so to not impact other tests
          ensure
            FileUtils.mv(engine_path + "/config", @project.absolute_path)
            FileUtils.rm_rf(engine_path)
          end
        end

        it "generates RBI files in the correct output directory" do
          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          @project.write!("lib/comment.rb", <<~RB)
            require "smart_properties"

            module Namespace
              class Comment
                include SmartProperties
                property! :body, accepts: String
              end
            end
          RB

          result = @project.tapioca("dsl --verbose --outdir rbis/")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

              processing  Namespace::Comment
                  create  rbis/namespace/comment.rbi
              processing  Post
                  create  rbis/post.rbi

            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_empty_stderr(result)

          assert_project_file_exist("rbis/namespace/comment.rbi")
          assert_project_file_exist("rbis/post.rbi")

          assert_success_status(result)

          @project.remove!("rbis/")
        end

        it "generates RBI files with verbose output" do
          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          @project.write!("lib/comment.rb", <<~RB)
            require "smart_properties"

            module Namespace
              class Comment
                include SmartProperties
                property! :body, accepts: String
              end
            end
          RB

          result = @project.tapioca("dsl --verbose")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

              processing  Namespace::Comment
                  create  sorbet/rbi/dsl/namespace/comment.rbi
              processing  Post
                  create  sorbet/rbi/dsl/post.rbi

            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_empty_stderr(result)

          assert_project_file_exist("sorbet/rbi/dsl/post.rbi")
          assert_project_file_exist("sorbet/rbi/dsl/namespace/comment.rbi")

          assert_success_status(result)
        end

        it "can generates RBI files quietly" do
          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          result = @project.tapioca("dsl --quiet")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...


            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_empty_stderr(result)

          assert_project_file_exist("sorbet/rbi/dsl/post.rbi")

          assert_success_status(result)
        end

        it "generates RBI files without header" do
          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          @project.tapioca("dsl --no-file-header Post")

          assert_project_file_equal("sorbet/rbi/dsl/post.rbi", <<~RBI)
            # typed: true

            class Post
              include SmartPropertiesGeneratedMethods

              module SmartPropertiesGeneratedMethods
                sig { returns(T.nilable(::String)) }
                def title; end

                sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
                def title=(title); end
              end
            end
          RBI
        end

        it "removes stale RBI files" do
          @project.write!("sorbet/rbi/dsl/to_be_deleted/foo.rbi")
          @project.write!("sorbet/rbi/dsl/to_be_deleted/baz.rbi")
          @project.write!("sorbet/rbi/dsl/does_not_exist.rbi")

          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          result = @project.tapioca("dsl")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

                  create  sorbet/rbi/dsl/post.rbi

            Removing stale RBI files...
                  remove  sorbet/rbi/dsl/does_not_exist.rbi
                  remove  sorbet/rbi/dsl/to_be_deleted/baz.rbi
                  remove  sorbet/rbi/dsl/to_be_deleted/foo.rbi

            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_empty_stderr(result)

          refute_project_file_exist("sorbet/rbi/dsl/does_not_exist.rbi")
          refute_project_file_exist("sorbet/rbi/dsl/to_be_deleted/foo.rbi")
          refute_project_file_exist("sorbet/rbi/dsl/to_be_deleted/baz.rbi")
          assert_project_file_exist("sorbet/rbi/dsl/post.rbi")

          assert_success_status(result)
        end

        it "does not crash with anonymous constants" do
          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          @project.write!("lib/job.rb", <<~RB)
            require "sidekiq"

            Class.new do
              include Sidekiq::Worker
            end
          RB

          result = @project.tapioca("dsl")

          assert_empty_stderr(result)
          assert_success_status(result)

          assert_project_file_exist("sorbet/rbi/dsl/post.rbi")
        end

        it "removes stale RBIs properly when running in parallel" do
          # Files that shouldn't be deleted
          @project.write!("sorbet/rbi/dsl/job.rbi")
          @project.write!("sorbet/rbi/dsl/post.rbi")

          # Files that should be deleted
          @project.write!("sorbet/rbi/dsl/to_be_deleted/foo.rbi")
          @project.write!("sorbet/rbi/dsl/to_be_deleted/baz.rbi")
          @project.write!("sorbet/rbi/dsl/does_not_exist.rbi")

          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          @project.write!("lib/job.rb", <<~RB)
            require "sidekiq"

            class Job
              include Sidekiq::Worker
              def perform(foo, bar)
              end
            end
          RB

          result = @project.tapioca("dsl --workers 2")

          assert_empty_stderr(result)
          assert_success_status(result)

          assert_project_file_exist("sorbet/rbi/dsl/post.rbi")
          assert_project_file_exist("sorbet/rbi/dsl/job.rbi")

          refute_project_file_exist("sorbet/rbi/dsl/does_not_exist.rbi")
          refute_project_file_exist("sorbet/rbi/dsl/to_be_deleted/foo.rbi")
          refute_project_file_exist("sorbet/rbi/dsl/to_be_deleted/baz.rbi")
        end

        it "removes stale RBI files of requested constants" do
          @project.write!("sorbet/rbi/dsl/user.rbi")

          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          @project.write!("lib/user.rb", <<~RB)
            class User; end
          RB

          result = @project.tapioca("dsl Post User")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

                  create  sorbet/rbi/dsl/post.rbi

            Removing stale RBI files...
                  remove  sorbet/rbi/dsl/user.rbi

            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_empty_stderr(result)

          assert_project_file_exist("sorbet/rbi/dsl/post.rbi")
          refute_project_file_exist("sorbet/rbi/dsl/user.rbi")

          assert_success_status(result)
        end

        it "can be called by path" do
          @project.write!("lib/models/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          @project.write!("lib/models/nested/user.rb", <<~RB)
            require "smart_properties"

            module Nested
              class User
                include SmartProperties
                property :name, accepts: String
              end
            end
          RB

          @project.write!("lib/job.rb", <<~RB)
            require "smart_properties"

            class User
              include SmartProperties
              property :name, accepts: String
            end
          RB

          result = @project.tapioca("dsl lib/models")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

                  create  sorbet/rbi/dsl/nested/user.rbi
                  create  sorbet/rbi/dsl/post.rbi

            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_empty_stderr(result)

          assert_project_file_exist("sorbet/rbi/dsl/post.rbi")
          assert_project_file_exist("sorbet/rbi/dsl/nested/user.rbi")
          refute_project_file_exist("sorbet/rbi/dsl/job.rbi")

          assert_success_status(result)
        end

        it "does not generate anything and errors for non-existent paths" do
          @project.write!("lib/models/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          result = @project.tapioca("dsl path/to/nowhere.rb")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

          OUT

          assert_equal(<<~ERR, result.err)
            No classes/modules can be matched for RBI generation.
            Please check that the requested classes/modules include processable DSL methods.
          ERR

          refute_project_file_exist("sorbet/rbi/dsl/post.rbi")

          refute_success_status(result)
        end

        it "does not generate anything but succeeds for real paths with no processable DSL" do
          @project.write!("lib/models/post.rb", <<~RB)
            class Foo
              class << self
                BAR = nil
              end
            end
          RB

          result = @project.tapioca("dsl lib/models")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...


            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_empty_stderr(result)

          refute_project_file_exist("sorbet/rbi/dsl/post.rbi")

          assert_success_status(result)
        end

        it "must run custom compilers" do
          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          @project.write!("lib/compilers/compiler_that_includes_bar_module.rb", <<~RB)
            require "post"

            class CompilerThatIncludesBarModuleInPost < Tapioca::Dsl::Compiler
              extend T::Sig

              ConstantType = type_member { { fixed: T.class_of(::Post) } }

              sig { override.void }
              def decorate
                root.create_path(constant) do |klass|
                  klass.create_module("GeneratedBar")
                  klass.create_include("GeneratedBar")
                end
              end

              sig { override.returns(T::Enumerable[Module]) }
              def self.gather_constants
                [::Post]
              end
            end
          RB

          @project.write!("lib/compilers/compiler_that_includes_foo_module.rb", <<~RB)
            require "post"

            class CompilerThatIncludesFooModuleInPost < Tapioca::Dsl::Compiler
              extend T::Sig

              ConstantType = type_member { { fixed: T.class_of(::Post) } }

              sig { override.void }
              def decorate
                root.create_path(constant) do |klass|
                  klass.create_module("GeneratedFoo")
                  klass.create_include("GeneratedFoo")
                end
              end

              sig { override.returns(T::Enumerable[Module]) }
              def self.gather_constants
                [::Post]
              end
            end
          RB

          result = @project.tapioca("dsl")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

                  create  sorbet/rbi/dsl/post.rbi

            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_empty_stderr(result)

          assert_project_file_equal("sorbet/rbi/dsl/post.rbi", <<~RBI)
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for dynamic methods in `Post`.
            # Please instead update this file by running `bin/tapioca dsl Post`.

            class Post
              include GeneratedBar
              include GeneratedFoo
              include SmartPropertiesGeneratedMethods

              module GeneratedBar; end
              module GeneratedFoo; end

              module SmartPropertiesGeneratedMethods
                sig { returns(T.nilable(::String)) }
                def title; end

                sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
                def title=(title); end
              end
            end
          RBI

          assert_success_status(result)
        end

        it "must respect `only` option" do
          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          @project.write!("lib/job.rb", <<~RB)
            require "sidekiq"

            class Job
              include Sidekiq::Worker
              def perform(foo, bar)
              end
            end
          RB

          @project.write!("lib/compilers/foo/compiler.rb", <<~RB)
            require "job"

            module Foo
              class Compiler < Tapioca::Dsl::Compiler
                extend T::Sig

                ConstantType = type_member { { fixed: Job } }

                sig { override.void }
                def decorate
                  root.create_path(constant) do |job|
                    job.create_module("FooModule")
                  end
                end

                sig { override.returns(T::Enumerable[Module]) }
                def self.gather_constants
                  [Job]
                end
              end
            end
          RB

          result = @project.tapioca("dsl --only SidekiqWorker Foo::Compiler")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

                  create  sorbet/rbi/dsl/job.rbi

            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_empty_stderr(result)

          assert_project_file_equal("sorbet/rbi/dsl/job.rbi", <<~RBI)
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for dynamic methods in `Job`.
            # Please instead update this file by running `bin/tapioca dsl Job`.

            class Job
              class << self
                sig { params(foo: T.untyped, bar: T.untyped).returns(String) }
                def perform_async(foo, bar); end

                sig { params(interval: T.any(DateTime, Time), foo: T.untyped, bar: T.untyped).returns(String) }
                def perform_at(interval, foo, bar); end

                sig { params(interval: Numeric, foo: T.untyped, bar: T.untyped).returns(String) }
                def perform_in(interval, foo, bar); end
              end

              module FooModule; end
            end
          RBI

          refute_project_file_exist("sorbet/rbi/dsl/post.rbi")

          assert_success_status(result)
        end

        it "errors if there are no matching compilers" do
          result = @project.tapioca("dsl --only NonexistentCompiler")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

          OUT

          assert_equal(<<~ERROR, result.err)
            Error: Cannot find compiler 'NonexistentCompiler'
          ERROR

          refute_success_status(result)
        end

        it "must respect `exclude` option" do
          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          @project.write!("lib/job.rb", <<~RB)
            require "sidekiq"

            class Job
              include Sidekiq::Worker
              def perform(foo, bar)
              end
            end
          RB

          @project.write!("lib/compilers/foo/compiler.rb", <<~RB)
            require "job"

            module Foo
              class Compiler < Tapioca::Dsl::Compiler
                extend T::Sig

                ConstantType = type_member { { fixed: Job } }

                sig { override.void }
                def decorate
                  root.create_path(constant) do |job|
                    job.create_module("FooModule")
                  end
                end

                sig { override.returns(T::Enumerable[Module]) }
                def self.gather_constants
                  [Job]
                end
              end
            end
          RB

          result = @project.tapioca("dsl --exclude SidekiqWorker Foo::Compiler")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

                  create  sorbet/rbi/dsl/post.rbi

            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_empty_stderr(result)

          refute_project_file_exist("sorbet/rbi/dsl/job.rbi")
          assert_project_file_exist("sorbet/rbi/dsl/post.rbi")

          assert_success_status(result)
        end

        it "errors if there are no matching `exclude` compilers" do
          result = @project.tapioca("dsl --exclude NonexistentCompiler")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

          OUT

          assert_equal(<<~ERROR, result.err)
            Error: Cannot find compiler 'NonexistentCompiler'
          ERROR

          refute_success_status(result)
        end

        it "must warn about reloaded constants and process only the newest one" do
          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end

            # Store in a global to assure that old copy does not get GC'ed.
            $post = Post

            Object.send(:remove_const, :Post)

            class Post
              include SmartProperties
              property :body, accepts: String
            end
          RB

          result = @project.tapioca("dsl")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

                  create  sorbet/rbi/dsl/post.rbi

            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_equal(<<~OUT, result.err)
            WARNING: Multiple constants with the same name: `Post`
            Make sure some object is not holding onto these constants during an app reload.
          OUT

          assert_success_status(result)

          assert_project_file_equal("sorbet/rbi/dsl/post.rbi", <<~RBI)
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for dynamic methods in `Post`.
            # Please instead update this file by running `bin/tapioca dsl Post`.

            class Post
              include SmartPropertiesGeneratedMethods

              module SmartPropertiesGeneratedMethods
                sig { returns(T.nilable(::String)) }
                def body; end

                sig { params(body: T.nilable(::String)).returns(T.nilable(::String)) }
                def body=(body); end
              end
            end
          RBI
        end

        describe "pending migrations" do
          before do
            @project.write!("db/migrate/202001010000_create_articles.rb", <<~RB)
              class CreateArticles < ActiveRecord::Migration[6.1]
                def change
                  create_table(:articles) do |t|
                    t.timestamps
                  end
                end
              end
            RB

            @project.write!("lib/database.rb", <<~RB)
              require "rake"

              namespace :db do
                task :abort_if_pending_migrations do
                  pending_migrations = Dir["\#{Kernel.__dir__}/../db/migrate/*.rb"]

                  if pending_migrations.any?
                    Kernel.puts "You have \#{pending_migrations.size} pending migration:"

                    pending_migrations.each do |pending_migration|
                      name = pending_migration.split("/").last
                      Kernel.puts name
                    end

                    Kernel.abort(%{Run `bin/rails db:migrate` to update your database then try again.})
                  end
                end
              end
            RB

            @project.require_real_gem("rake", "13.0.6")
            @project.require_real_gem("activerecord")
            @project.bundle_install!
          end

          it "aborts if there are pending migrations" do
            @project.write!("lib/post.rb", <<~RB)
              class Post < ActiveRecord::Base
              end
            RB

            result = @project.tapioca("dsl Post")

            # FIXME: print the error to the correct stream
            assert_equal(<<~OUT, result.out)
              Loading DSL extension classes... Done
              Loading Rails application... Done
              Loading DSL compiler classes... Done
              Compiling DSL RBI files...

              You have 1 pending migration:
              202001010000_create_articles.rb
            OUT

            assert_equal(<<~ERR, result.err)
              Run `bin/rails db:migrate` to update your database then try again.
            ERR

            refute_success_status(result)
          end

          it "aborts if there are pending migrations and no arg was passed" do
            @project.write!("lib/post.rb", <<~RB)
              class Post < ActiveRecord::Base
              end
            RB

            result = @project.tapioca("dsl")

            # FIXME: print the error to the correct stream
            assert_equal(<<~OUT, result.out)
              Loading DSL extension classes... Done
              Loading Rails application... Done
              Loading DSL compiler classes... Done
              Compiling DSL RBI files...

              You have 1 pending migration:
              202001010000_create_articles.rb
            OUT

            assert_equal(<<~ERR, result.err)
              Run `bin/rails db:migrate` to update your database then try again.
            ERR

            refute_success_status(result)
          end

          it "does not abort if there are pending migrations but no active record models" do
            @project.write!("lib/post.rb", <<~RB)
              require "smart_properties"

              class Post
                include SmartProperties
                property :title, accepts: String
              end
            RB

            result = @project.tapioca("dsl Post")

            assert_equal(<<~OUT, result.out)
              Loading DSL extension classes... Done
              Loading Rails application... Done
              Loading DSL compiler classes... Done
              Compiling DSL RBI files...

                    create  sorbet/rbi/dsl/post.rbi

              Done

              Checking generated RBI files...  Done
                No errors found

              All operations performed in working directory.
              Please review changes and commit them.
            OUT

            assert_empty_stderr(result)

            assert_project_file_exist("sorbet/rbi/dsl/post.rbi")

            assert_success_status(result)
          end
        end

        it "overwrites existing RBIs without user input" do
          @project.write!("sorbet/rbi/dsl/image.rbi")

          @project.write!("lib/image.rb", <<~RB)
            require "smart_properties"

            class Image
              include SmartProperties

              property :title, accepts: String
              property :src, accepts: String
            end
          RB

          result = @project.tapioca("dsl")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

                   force  sorbet/rbi/dsl/image.rbi

            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_empty_stderr(result)

          assert_project_file_exist("sorbet/rbi/dsl/image.rbi")

          assert_success_status(result)
        end

        it "generates the correct RBIs when running in parallel" do
          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          @project.write!("lib/job.rb", <<~RB)
            require "sidekiq"

            class Job
              include Sidekiq::Worker
              def perform(foo, bar)
              end
            end
          RB

          @project.write!("lib/image.rb", <<~RB)
            require "smart_properties"

            class Image
              include SmartProperties

              property :title, accepts: String
              property :src, accepts: String
            end
          RB

          result = @project.tapioca("dsl --workers 3")

          assert_empty_stderr(result)
          assert_success_status(result)

          assert_project_file_exist("sorbet/rbi/dsl/post.rbi")
          assert_project_file_exist("sorbet/rbi/dsl/job.rbi")
          assert_project_file_exist("sorbet/rbi/dsl/image.rbi")
        end

        it "shows a helpful error message when unexpected errors occur" do
          @project.write!("lib/post.rb", <<~RB)
            class Post
            end
          RB

          @project.write!("lib/compilers/post_compiler_that_raises.rb", <<~RB)
            require "post"

            class PostCompilerThatRaises < Tapioca::Dsl::Compiler
              def decorate
                raise "Some unexpected error happened"
              end

              def self.gather_constants
                [::Post]
              end
            end
          RB

          result = @project.tapioca("dsl")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

          OUT

          assert_stderr_includes(result, "Error: `PostCompilerThatRaises` failed to generate RBI for `Post`")
          assert_stderr_includes(result, "Some unexpected error happened")

          refute_project_file_exist("sorbet/rbi/dsl/post.rbi")
          refute_success_status(result)
        end

        it "generates RBIs for lower versions of activerecord-typedstore" do
          @project.require_real_gem("activerecord-typedstore", "1.4.0")
          @project.require_real_gem("sqlite3")
          @project.bundle_install!
          @project.write!("lib/post.rb", <<~RB)
            require "active_record"
            require "active_record/typed_store"

            ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

            class Post < ActiveRecord::Base
              typed_store :metadata do |s|
                s.string(:reviewer)
              end
            end
          RB

          result = @project.tapioca("dsl Post --only=ActiveRecordTypedStore")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

                  create  sorbet/rbi/dsl/post.rbi

            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_empty_stderr(result)

          assert_project_file_equal("sorbet/rbi/dsl/post.rbi", <<~RBI)
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for dynamic methods in `Post`.
            # Please instead update this file by running `bin/tapioca dsl Post`.

            class Post
              include StoreAccessors

              module StoreAccessors
                sig { returns(T.nilable(String)) }
                def reviewer; end

                sig { params(reviewer: T.nilable(String)).returns(T.nilable(String)) }
                def reviewer=(reviewer); end

                sig { returns(T::Boolean) }
                def reviewer?; end

                sig { returns(T.nilable(String)) }
                def reviewer_before_last_save; end

                sig { returns(T.nilable([T.nilable(String), T.nilable(String)])) }
                def reviewer_change; end

                sig { returns(T::Boolean) }
                def reviewer_changed?; end

                sig { returns(T.nilable(String)) }
                def reviewer_was; end

                sig { returns(T.nilable([T.nilable(String), T.nilable(String)])) }
                def saved_change_to_reviewer; end

                sig { returns(T::Boolean) }
                def saved_change_to_reviewer?; end
              end
            end
          RBI

          assert_success_status(result)
        end
      end

      describe "verify" do
        before(:all) do
          @project.require_real_gem("smart_properties", "1.15.0")
          @project.require_real_gem("sidekiq", "6.2.1")
          @project.bundle_install!

          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          @project.write!("lib/job.rb", <<~RB)
            require "sidekiq"

            class Job
              include Sidekiq::Worker
              def perform(foo, bar)
              end
            end
          RB
        end

        after do
          @project.remove!("sorbet/rbi/dsl")
        end

        it "does nothing and returns exit status 0 with no changes" do
          @project.tapioca("dsl")
          result = @project.tapioca("dsl --verify")

          assert_stdout_includes(result, <<~OUT)
            Nothing to do, all RBIs are up-to-date.
          OUT

          assert_empty_stderr(result)
          assert_success_status(result)
        end

        it "advises of removed file(s) and returns exit status 1 when files are excluded" do
          @project.tapioca("dsl")
          result = @project.tapioca("dsl --verify --exclude SmartProperties")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Checking for out-of-date RBIs...


          OUT

          assert_equal(<<~ERROR, result.err)
            RBI files are out-of-date. In your development environment, please run:
              `bin/tapioca dsl`
            Once it is complete, be sure to commit and push any changes
            If you don't observe any changes after running the command locally, ensure your database is in a good
            state e.g. run `bin/rails db:reset`

            Reason:
              File(s) removed:
              - sorbet/rbi/dsl/post.rbi
          ERROR

          refute_success_status(result)
        end

        it "advises of new file(s) and returns exit status 1 with new files" do
          @project.tapioca("dsl")

          @project.write!("lib/image.rb", <<~RB)
            require "smart_properties"

            class Image
              include(SmartProperties)

              property :title, accepts: String
            end
          RB

          result = @project.tapioca("dsl --verify")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Checking for out-of-date RBIs...


          OUT

          assert_equal(<<~ERROR, result.err)
            RBI files are out-of-date. In your development environment, please run:
              `bin/tapioca dsl`
            Once it is complete, be sure to commit and push any changes
            If you don't observe any changes after running the command locally, ensure your database is in a good
            state e.g. run `bin/rails db:reset`

            Reason:
              File(s) added:
              - sorbet/rbi/dsl/image.rbi
          ERROR

          refute_success_status(result)

          @project.remove!("lib/image.rb")
        end

        it "advises of modified file(s) and returns exit status 1 with modified file" do
          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          @project.tapioca("dsl")

          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
              property :desc, accepts: String
            end
          RB

          result = @project.tapioca("dsl --verify")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Checking for out-of-date RBIs...


          OUT

          assert_equal(<<~ERROR, result.err)
            RBI files are out-of-date. In your development environment, please run:
              `bin/tapioca dsl`
            Once it is complete, be sure to commit and push any changes
            If you don't observe any changes after running the command locally, ensure your database is in a good
            state e.g. run `bin/rails db:reset`

            Reason:
              File(s) changed:
              - sorbet/rbi/dsl/post.rbi
          ERROR

          refute_success_status(result)
        end
      end

      describe "strictness" do
        it "must turn the strictness of gem RBI files with errors to false" do
          @project.require_real_gem("smart_properties", "1.15.0")
          @project.bundle_install!

          @project.write!("sorbet/rbi/gems/foo@0.0.1.rbi", <<~RBI)
            # typed: true

            module Post::SmartPropertiesGeneratedMethods
              def foo; end
            end
          RBI

          @project.write!("sorbet/rbi/gems/bar@1.0.0.rbi", <<~RBI)
            # typed: true

            module Post::SmartPropertiesGeneratedMethods
              sig { params(title: T.nilable(::String), subtitle: T.nilable(::String)).returns(T.nilable(::String)) }
              def title=(title, subtitle); end
            end
          RBI

          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB

          result = @project.tapioca("dsl Post")

          assert_stdout_includes(result, <<~OUT)
            Checking generated RBI files...  Done

              Changed strictness of sorbet/rbi/gems/bar@1.0.0.rbi to `typed: false` (conflicting with DSL files)
          OUT

          assert_file_strictness("true", "sorbet/rbi/gems/foo@0.0.1.rbi")
          assert_file_strictness("false", "sorbet/rbi/gems/bar@1.0.0.rbi")
          assert_file_strictness("true", "sorbet/rbi/dsl/post.rbi")

          assert_empty_stderr(result)
          assert_success_status(result)

          @project.remove!("sorbet/rbi/gems")
          @project.remove!("sorbet/rbi/dsl")
        end
      end

      describe "custom compilers" do
        it "must load custom compilers from gems" do
          @project.write!("lib/post.rb", <<~RB)
            class Post
            end
          RB

          foo = mock_gem("foo", "0.0.1") do
            write!("lib/tapioca/dsl/compilers/post_compiler.rb", <<~RB)
              require "post"
              require "tapioca/dsl"

              class PostCompiler < Tapioca::Dsl::Compiler
                extend T::Sig

                ConstantType = type_member { { fixed: T.class_of(::Post) } }

                sig { override.void }
                def decorate
                  root.create_path(constant) do |klass|
                    klass.create_module("GeneratedBar")
                    klass.create_include("GeneratedBar")
                  end
                end

                sig { override.returns(T::Enumerable[Module]) }
                def self.gather_constants
                  [::Post]
                end
              end
            RB
          end

          @project.require_mock_gem(foo)
          @project.bundle_install!

          result = @project.tapioca("dsl Post")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

                  create  sorbet/rbi/dsl/post.rbi

            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_project_file_equal("sorbet/rbi/dsl/post.rbi", <<~RBI)
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for dynamic methods in `Post`.
            # Please instead update this file by running `bin/tapioca dsl Post`.

            class Post
              include GeneratedBar

              module GeneratedBar; end
            end
          RBI

          assert_empty_stderr(result)
          assert_success_status(result)
        end

        it "must be able to load custom compilers without a full require" do
          @project.bundle_install!

          @project.write!("lib/post.rb", <<~RB)
            class Post
            end
          RB

          @project.write!("lib/compilers/post_compiler.rb", <<~RB)
            require "post"
            require "tapioca/dsl"

            class PostCompiler < Tapioca::Dsl::Compiler
              extend T::Sig

              ConstantType = type_member { { fixed: T.class_of(::Post) } }

              sig { override.void }
              def decorate
                root.create_path(constant) do |klass|
                  klass.create_module("GeneratedBar")
                  klass.create_include("GeneratedBar")
                end
              end

              sig { override.returns(T::Enumerable[Module]) }
              def self.gather_constants
                [::Post]
              end
            end
          RB

          @project.write!("bin/generate", <<~RB)
            require_relative "../config/environment"

            file = RBI::File.new(strictness: "strong")
            pipeline = Tapioca::Dsl::Pipeline.new(requested_constants: [])
            PostCompiler.new(pipeline, file.root, Post).decorate
            puts Tapioca::DEFAULT_RBI_FORMATTER.print_file(file)
          RB

          result = @project.bundle_exec("ruby bin/generate")

          assert_equal(<<~OUT, result.out)
            # typed: strong

            class Post
              include GeneratedBar

              module GeneratedBar; end
            end
          OUT

          assert_empty_stderr(result)
          assert_success_status(result)
        end
      end

      describe "custom extensions" do
        after do
          project.remove!("sorbet/rbi/gems")
          project.remove!("sorbet/rbi/dsl")
          project.remove!("sorbet/tapioca")
        end

        it "must load custom extensions from gems" do
          @project.write!("lib/credit_card.rb", <<~RB)
            require "encryptable"

            class CreditCard
              include Encryptable

              attr_encrypted :number
            end
          RB

          encryptable = mock_gem("encryptable", "0.0.1") do
            write!("lib/encryptable.rb", <<~RB)
              module Encryptable
                def self.included(base)
                  base.extend(ClassMethods)
                end

                module ClassMethods
                  def attr_encrypted(attr_name)
                    attr_accessor(attr_name)

                    encrypted_attr_name = :"\#{attr_name}_encrypted"

                    define_method(encrypted_attr_name) do
                      value = send(attr_name)
                      encrypt(value)
                    end

                    define_method("\#{encrypted_attr_name}=") do |value|
                      send("\#{attr_name}=", decrypt(value))
                    end
                  end
                end

                private

                def encrypt(value)
                  value.unpack("H*").first
                end

                def decrypt(value)
                  [value].pack("H*")
                end
              end
            RB

            write!("lib/tapioca/dsl/extensions/encryptable.rb", <<~RB)
              require "encryptable"

              module Tapioca
                module Extensions
                  module Encryptable
                    attr_reader :__tapioca_encrypted_attributes

                    def attr_encrypted(attr_name)
                      @__tapioca_encrypted_attributes ||= []
                      @__tapioca_encrypted_attributes << attr_name.to_s

                      super
                    end

                    ::Encryptable::ClassMethods.prepend(self)
                  end
                end
              end
            RB

            write!("lib/tapioca/dsl/compilers/encryptable.rb", <<~RB)
              require "encryptable"

              module Tapioca
                module Compilers
                  class Encryptable < Tapioca::Dsl::Compiler
                    extend T::Sig

                    ConstantType = type_member {{ fixed: T.class_of(Encryptable) }}

                    sig { override.returns(T::Enumerable[Module]) }
                    def self.gather_constants
                      # Collect all the classes that include Encryptable
                      all_classes.select { |c| c < ::Encryptable }
                    end

                    sig { override.void }
                    def decorate
                      # Create a RBI definition for each class that includes Encryptable
                      root.create_path(constant) do |klass|
                        # For each encrypted attribute we find in the class
                        constant.__tapioca_encrypted_attributes.each do |attr_name|
                          # Create the RBI definitions for all the missing methods
                          klass.create_method(attr_name, return_type: "String")
                          klass.create_method("\#{attr_name}=", parameters: [ create_param("value", type: "String") ], return_type: "void")
                          klass.create_method("\#{attr_name}_encrypted", return_type: "String")
                          klass.create_method("\#{attr_name}_encrypted=", parameters: [ create_param("value", type: "String") ], return_type: "void")
                        end
                      end
                    end
                  end
                end
              end
            RB
          end

          @project.require_mock_gem(encryptable)
          @project.bundle_install!

          result = @project.tapioca("dsl CreditCard")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

                  create  sorbet/rbi/dsl/credit_card.rbi

            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_project_file_equal("sorbet/rbi/dsl/credit_card.rbi", <<~RBI)
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for dynamic methods in `CreditCard`.
            # Please instead update this file by running `bin/tapioca dsl CreditCard`.

            class CreditCard
              sig { returns(String) }
              def number; end

              sig { params(value: String).void }
              def number=(value); end

              sig { returns(String) }
              def number_encrypted; end

              sig { params(value: String).void }
              def number_encrypted=(value); end
            end
          RBI

          assert_empty_stderr(result)
          assert_success_status(result)
        end

        it "must load custom extensions from the Sorbet directory" do
          @project.write!("lib/credit_card.rb", <<~RB)
            require "encryptable"

            class CreditCard
              include Encryptable

              attr_encrypted :number
            end
          RB

          encryptable = mock_gem("encryptable", "0.0.1") do
            write!("lib/encryptable.rb", <<~RB)
              module Encryptable
                def self.included(base)
                  base.extend(ClassMethods)
                end

                module ClassMethods
                  def attr_encrypted(attr_name)
                    attr_accessor(attr_name)

                    encrypted_attr_name = :"\#{attr_name}_encrypted"

                    define_method(encrypted_attr_name) do
                      value = send(attr_name)
                      encrypt(value)
                    end

                    define_method("\#{encrypted_attr_name}=") do |value|
                      send("\#{attr_name}=", decrypt(value))
                    end
                  end
                end

                private

                def encrypt(value)
                  value.unpack("H*").first
                end

                def decrypt(value)
                  [value].pack("H*")
                end
              end
            RB
          end

          @project.write!("sorbet/tapioca/extensions/encryptable.rb", <<~RB)
            require "encryptable"

            module Tapioca
              module Extensions
                module Encryptable
                  attr_reader :__tapioca_encrypted_attributes

                  def attr_encrypted(attr_name)
                    @__tapioca_encrypted_attributes ||= []
                    @__tapioca_encrypted_attributes << attr_name.to_s

                    super
                  end

                  ::Encryptable::ClassMethods.prepend(self)
                end
              end
            end
          RB

          @project.write!("sorbet/tapioca/compilers/encryptable.rb", <<~RB)
            require "encryptable"

            module Tapioca
              module Compilers
                class Encryptable < Tapioca::Dsl::Compiler
                  extend T::Sig

                  ConstantType = type_member {{ fixed: T.class_of(Encryptable) }}

                  sig { override.returns(T::Enumerable[Module]) }
                  def self.gather_constants
                    # Collect all the classes that include Encryptable
                    all_classes.select { |c| c < ::Encryptable }
                  end

                  sig { override.void }
                  def decorate
                    # Create a RBI definition for each class that includes Encryptable
                    root.create_path(constant) do |klass|
                      # For each encrypted attribute we find in the class
                      constant.__tapioca_encrypted_attributes.each do |attr_name|
                        # Create the RBI definitions for all the missing methods
                        klass.create_method(attr_name, return_type: "String")
                        klass.create_method("\#{attr_name}=", parameters: [ create_param("value", type: "String") ], return_type: "void")
                        klass.create_method("\#{attr_name}_encrypted", return_type: "String")
                        klass.create_method("\#{attr_name}_encrypted=", parameters: [ create_param("value", type: "String") ], return_type: "void")
                      end
                    end
                  end
                end
              end
            end
          RB

          @project.require_mock_gem(encryptable)
          @project.bundle_install!

          result = @project.tapioca("dsl CreditCard")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...

                  create  sorbet/rbi/dsl/credit_card.rbi

            Done

            Checking generated RBI files...  Done
              No errors found

            All operations performed in working directory.
            Please review changes and commit them.
          OUT

          assert_project_file_equal("sorbet/rbi/dsl/credit_card.rbi", <<~RBI)
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for dynamic methods in `CreditCard`.
            # Please instead update this file by running `bin/tapioca dsl CreditCard`.

            class CreditCard
              sig { returns(String) }
              def number; end

              sig { params(value: String).void }
              def number=(value); end

              sig { returns(String) }
              def number_encrypted; end

              sig { params(value: String).void }
              def number_encrypted=(value); end
            end
          RBI

          assert_empty_stderr(result)
          assert_success_status(result)
        end

        it "halts upon load errors when extension cannot be loaded" do
          @project.write!("lib/post.rb", <<~RB)
            class Post
            end
          RB

          @project.write!("sorbet/tapioca/extensions/test.rb", <<~RB)
            puts "Hi from test extension"
            raise "Raising from test extension"
          RB

          result = @project.tapioca("dsl Post")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Hi from test extension
          OUT

          err = "tapioca/tests/dsl_spec/project/sorbet/tapioca/extensions/test.rb:2:in `<top (required)>': " \
            "Raising from test extension (RuntimeError)"
          assert_stderr_includes(result, err)

          refute_success_status(result)
        end
      end

      describe "sanity" do
        before(:all) do
          @project.require_real_gem("smart_properties", "1.15.0")
          @project.bundle_install!
          @project.tapioca("configure")

          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB
        end

        after do
          project.remove!("sorbet/rbi/gems")
          project.remove!("sorbet/rbi/dsl")
        end

        it "must display an error message when a generated gem RBI file contains a parse error" do
          @project.write!("sorbet/rbi/dsl/bar.rbi", <<~RBI)
            # typed: true

            module Bar
              # This method is missing a `)`
              sig { params(block: T.proc.params(x: T.any(String, Integer).void).void }
              def bar(&block); end
            end
          RBI

          result = @project.tapioca("dsl Post")

          assert_equal(<<~ERR, result.err)
            ##### INTERNAL ERROR #####

            There are parse errors in the generated RBI files.

            This seems related to a bug in Tapioca.
            Please open an issue at https://github.com/Shopify/tapioca/issues/new with the following information:

            Tapioca v#{Tapioca::VERSION}

            Command:
              bin/tapioca dsl Post

            Compilers:
              Tapioca::Dsl::Compilers::SmartProperties

            Errors:
              sorbet/rbi/dsl/bar.rbi:5: unexpected token tRCURLY (2001)
              sorbet/rbi/dsl/bar.rbi:6: unexpected token "end" (2001)

            ##########################
          ERR

          refute_success_status(result)
        end
      end

      describe "environment" do
        before(:all) do
          @project.tapioca("configure")

          @project.write!("lib/post.rb", <<~RB)
            require "smart_properties"

            $stderr.puts "RAILS ENVIRONMENT: \#{ENV["RAILS_ENV"]}"
            $stderr.puts "RACK ENVIRONMENT: \#{ENV["RACK_ENV"]}"

            class Post
              include SmartProperties
              property :title, accepts: String
            end

            if ENV["RAILS_ENV"] == "development"
              class Post::Rails < Post
              end
            end

            if ENV["RACK_ENV"] == "development"
              class Post::Rack < Post
              end
            end
          RB

          @project.require_real_gem("smart_properties", "1.15.0")
          @project.bundle_install!
        end

        it "must default to `development` as environment" do
          result = @project.tapioca("dsl")

          assert_equal(<<~OUT, result.err)
            RAILS ENVIRONMENT: development
            RACK ENVIRONMENT: development
          OUT

          assert_project_file_equal("sorbet/rbi/dsl/post/rack.rbi", <<~RBI)
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for dynamic methods in `Post::Rack`.
            # Please instead update this file by running `bin/tapioca dsl Post::Rack`.

            class Post::Rack
              include SmartPropertiesGeneratedMethods

              module SmartPropertiesGeneratedMethods
                sig { returns(T.nilable(::String)) }
                def title; end

                sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
                def title=(title); end
              end
            end
          RBI

          assert_project_file_equal("sorbet/rbi/dsl/post/rails.rbi", <<~RBI)
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for dynamic methods in `Post::Rails`.
            # Please instead update this file by running `bin/tapioca dsl Post::Rails`.

            class Post::Rails
              include SmartPropertiesGeneratedMethods

              module SmartPropertiesGeneratedMethods
                sig { returns(T.nilable(::String)) }
                def title; end

                sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
                def title=(title); end
              end
            end
          RBI

          assert_success_status(result)
        end

        it "must accept another value for environment" do
          result = @project.tapioca("dsl --environment staging")

          assert_success_status(result)

          refute_project_file_exist("sorbet/rbi/dsl/post/rack.rbi")
          refute_project_file_exist("sorbet/rbi/dsl/post/rails.rbi")

          assert_equal(<<~OUT, result.err)
            RAILS ENVIRONMENT: staging
            RACK ENVIRONMENT: staging
          OUT
        end
      end

      describe "list compilers" do
        before(:all) do
          @project.tapioca("configure")
          @project.require_real_gem("smart_properties")
          @project.require_real_gem("sidekiq")
          @project.require_real_gem("activerecord")
          @project.bundle_install!

          @project.write!("lib/compilers/post_compiler.rb", <<~RB)
            require "tapioca/dsl"

            class PostCompiler < Tapioca::Dsl::Compiler
            end
          RB
        end

        it "lists all Tapioca bundled compilers" do
          result = @project.tapioca("dsl --list-compilers")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done

            Loaded DSL compiler classes:

              PostCompiler                                             enabled
              Tapioca::Dsl::Compilers::ActiveModelAttributes           enabled
              Tapioca::Dsl::Compilers::ActiveModelSecurePassword       enabled
              Tapioca::Dsl::Compilers::ActiveRecordAssociations        enabled
              Tapioca::Dsl::Compilers::ActiveRecordColumns             enabled
              Tapioca::Dsl::Compilers::ActiveRecordDelegatedTypes      enabled
              Tapioca::Dsl::Compilers::ActiveRecordEnum                enabled
              Tapioca::Dsl::Compilers::ActiveRecordRelations           enabled
              Tapioca::Dsl::Compilers::ActiveRecordScope               enabled
              Tapioca::Dsl::Compilers::ActiveRecordSecureToken         enabled
              Tapioca::Dsl::Compilers::ActiveSupportConcern            enabled
              Tapioca::Dsl::Compilers::ActiveSupportCurrentAttributes  enabled
              Tapioca::Dsl::Compilers::MixedInClassAttributes          enabled
              Tapioca::Dsl::Compilers::SidekiqWorker                   enabled
              Tapioca::Dsl::Compilers::SmartProperties                 enabled
          OUT

          assert_empty_stderr(result)
          assert_success_status(result)
        end

        it "lists excluded compilers" do
          result = @project.tapioca("dsl --list-compilers --exclude SmartProperties ActiveRecordEnum")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done

            Loaded DSL compiler classes:

              PostCompiler                                             enabled
              Tapioca::Dsl::Compilers::ActiveModelAttributes           enabled
              Tapioca::Dsl::Compilers::ActiveModelSecurePassword       enabled
              Tapioca::Dsl::Compilers::ActiveRecordAssociations        enabled
              Tapioca::Dsl::Compilers::ActiveRecordColumns             enabled
              Tapioca::Dsl::Compilers::ActiveRecordDelegatedTypes      enabled
              Tapioca::Dsl::Compilers::ActiveRecordEnum                disabled
              Tapioca::Dsl::Compilers::ActiveRecordRelations           enabled
              Tapioca::Dsl::Compilers::ActiveRecordScope               enabled
              Tapioca::Dsl::Compilers::ActiveRecordSecureToken         enabled
              Tapioca::Dsl::Compilers::ActiveSupportConcern            enabled
              Tapioca::Dsl::Compilers::ActiveSupportCurrentAttributes  enabled
              Tapioca::Dsl::Compilers::MixedInClassAttributes          enabled
              Tapioca::Dsl::Compilers::SidekiqWorker                   enabled
              Tapioca::Dsl::Compilers::SmartProperties                 disabled
          OUT

          assert_empty_stderr(result)
          assert_success_status(result)
        end

        it "lists enabled compilers" do
          result = @project.tapioca("dsl --list-compilers --only SmartProperties ActiveRecordEnum")

          assert_equal(<<~OUT, result.out)
            Loading DSL extension classes... Done
            Loading Rails application... Done
            Loading DSL compiler classes... Done

            Loaded DSL compiler classes:

              PostCompiler                                             disabled
              Tapioca::Dsl::Compilers::ActiveModelAttributes           disabled
              Tapioca::Dsl::Compilers::ActiveModelSecurePassword       disabled
              Tapioca::Dsl::Compilers::ActiveRecordAssociations        disabled
              Tapioca::Dsl::Compilers::ActiveRecordColumns             disabled
              Tapioca::Dsl::Compilers::ActiveRecordDelegatedTypes      disabled
              Tapioca::Dsl::Compilers::ActiveRecordEnum                enabled
              Tapioca::Dsl::Compilers::ActiveRecordRelations           disabled
              Tapioca::Dsl::Compilers::ActiveRecordScope               disabled
              Tapioca::Dsl::Compilers::ActiveRecordSecureToken         disabled
              Tapioca::Dsl::Compilers::ActiveSupportConcern            disabled
              Tapioca::Dsl::Compilers::ActiveSupportCurrentAttributes  disabled
              Tapioca::Dsl::Compilers::MixedInClassAttributes          disabled
              Tapioca::Dsl::Compilers::SidekiqWorker                   disabled
              Tapioca::Dsl::Compilers::SmartProperties                 enabled
          OUT

          assert_empty_stderr(result)
          assert_success_status(result)
        end
      end

      describe "halt-upon-load-error" do
        before(:all) do
          @project.write!("config/environment.rb", <<~RB)
            require_relative "application.rb"
          RB

          @project.write!("config/application.rb", <<~RB)
            require "rails"

            module Test
              class Application < Rails::Application
                raise "Error during application loading"
              end
            end
          RB

          @project.require_real_gem("rails")
          @project.bundle_install!
        end

        after(:all) do
          @project.remove!("config/application.rb")
        end

        it "halts upon load errors when rails application cannot be loaded" do
          res = @project.tapioca("dsl")

          out = "Tapioca attempted to load the Rails application after encountering a `config/application.rb` file, " \
            "but it failed. If your application uses Rails please ensure it can be loaded correctly before " \
            "generating RBIs. If your application does not use Rails and you wish to continue RBI generation " \
            "please pass `--no-halt-upon-load-error` to the tapioca command in sorbet/tapioca/config.yml or in CLI." \
            "\nError during application loading"
          assert_stdout_includes(res, out)
          err = "tapioca/tests/dsl_spec/project/config/application.rb:5:in `<class:Application>': Error during " \
            "application loading (RuntimeError)"
          assert_stderr_includes(res, err)
          refute_success_status(res)
        end

        it "output errors when rails application cannot be loaded with --no-halt-upon-load-error flag" do
          res = @project.tapioca("dsl --no-halt-upon-load-error")

          out = "Tapioca attempted to load the Rails application after encountering a `config/application.rb` file, " \
            "but it failed. If your application uses Rails please ensure it can be loaded correctly before " \
            "generating RBIs. If your application does not use Rails and you wish to continue RBI generation " \
            "please pass `--no-halt-upon-load-error` to the tapioca command in sorbet/tapioca/config.yml or in CLI." \
            "\nError during application loading"
          assert_stdout_includes(res, out)
          assert_stdout_includes(res, "tapioca/tests/dsl_spec/project/config/application.rb:5:in `<class:Application>'")
          assert_stdout_includes(res, <<~OUT)
            Continuing RBI generation without loading the Rails application.
            Done
            Loading DSL compiler classes... Done
            Compiling DSL RBI files...
          OUT
          assert_success_status(res)
        end
      end
    end
  end
end
