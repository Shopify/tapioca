# typed: strict
# frozen_string_literal: true

require "spec_helper"
require "yaml"

module Tapioca
  class InitSpec < SpecWithProject
    describe "cli::load" do
      describe "generate dsl" do
        before(:all) do
          project.require_real_gem("smart_properties", "1.15.0")
          project.bundle_install

          project.write("lib/post.rb", <<~RB)
            require "smart_properties"

            class Post
              include SmartProperties
              property :title, accepts: String
            end
          RB
        end

        after do
          @project.remove("sorbet/tapioca/load.rb")
          @project.remove("sorbet/rbi/dsl")
        end

        describe "with rails app" do
          before(:all) do
            project.write("config/application.rb", <<~RB)
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

            project.write("config/environment.rb", <<~RB)
              require_relative "application.rb"
            RB
          end

          it "loads the app correctly in a default rails app" do
            result = @project.tapioca("dsl Post")

            assert_success_status(result)
            assert_project_file_exist("sorbet/rbi/dsl/post.rbi")
          end

          it "executes custom loaders found in sorbet/tapioca/load.rb" do
            @project.write("sorbet/tapioca/load.rb", <<~RB)
              puts "Custom loader file loaded!"
              exit 0
            RB

            result = @project.tapioca("dsl Post")

            assert_includes(result.out, "Custom loader file loaded!")
            assert_success_status(result)
            refute_project_file_exist("sorbet/rbi/dsl/post.rbi")
          end

          it "lets errors propagate from custom loaders propagate" do
            @project.write("sorbet/tapioca/load.rb", <<~RB)
              raise "Some kind of error!"
            RB

            result = @project.tapioca("dsl Post")

            assert_includes(result.err, "Some kind of error!")
            refute_success_status(result)
          end

          it "ensures custom loaders call Tapioca.load_for_dsl" do
            @project.write("sorbet/tapioca/load.rb", "")

            result = @project.tapioca("dsl Post")

            assert_includes(result.err, <<~ERR)
              To provide a custom application loader, `Tapioca.load_for_dsl` must be called with a block (RuntimeError)

                Tapioca.load_for_dsl do
                  # Add custom load instructions here
                end
            ERR

            refute_success_status(result)
            refute_project_file_exist("sorbet/rbi/dsl/post.rbi")
          end

          it "ensures custom loaders are passed a block" do
            @project.write("sorbet/tapioca/load.rb", <<~RB)
              Tapioca.load_for_dsl
            RB

            result = @project.tapioca("dsl Post")

            assert_includes(result.err, <<~ERR)
              To provide a custom application loader, `Tapioca.load_for_dsl` must be called with a block (RuntimeError)

                Tapioca.load_for_dsl do
                  # Add custom load instructions here
                end
            ERR

            refute_success_status(result)
            refute_project_file_exist("sorbet/rbi/dsl/post.rbi")
          end

          it "loads the rails app correctly with a custom loader" do
            @project.write("sorbet/tapioca/load.rb", <<~RB)
              Tapioca.load_for_dsl do
                load_dsl_extensions
                load_application(eager_load: @requested_constants.empty?)
                load_dsl_compilers
              end
            RB

            result = @project.tapioca("dsl Post")

            assert_includes(result.out, "Loading Rails application... Done")
            assert_success_status(result)
            assert_project_file_exist("sorbet/rbi/dsl/post.rbi")
          end

          it "loads the rails app correctly with a custom loader using the default loader" do
            @project.write("sorbet/tapioca/load.rb", <<~RB)
              Tapioca.load_for_dsl do
                load_dsl_defaults
              end
            RB

            result = @project.tapioca("dsl Post")

            assert_includes(result.out, "Loading Rails application... Done")
            assert_success_status(result)
            assert_project_file_exist("sorbet/rbi/dsl/post.rbi")
          end

          it "loads the rails app and the custom compilers correctly using the default loader" do
            @project.write("sorbet/tapioca/load.rb", <<~RB)
              Tapioca.load_for_dsl do
                load_dsl_defaults

                require_relative "custom_compiler.rb"
              end
            RB

            @project.write("sorbet/tapioca/custom_compiler.rb", <<~RB)
              require "post"

              class CustomCompiler < Tapioca::Dsl::Compiler
                extend T::Sig

                ConstantType = type_member(fixed: T.class_of(::Post))

                sig { override.void }
                def decorate
                  root.create_path(constant) do |klass|
                    klass.create_method(:custom_method)
                  end
                end

                sig { override.returns(T::Enumerable[Module]) }
                def self.gather_constants
                  [::Post]
                end
              end
            RB

            result = @project.tapioca("dsl Post")

            @project.remove("sorbet/tapioca/custom_compiler.rb")

            assert_includes(result.out, "Loading Rails application... Done")
            assert_success_status(result)
            assert_project_file_equal("sorbet/rbi/dsl/post.rbi", <<~RBI)
              # typed: true

              # DO NOT EDIT MANUALLY
              # This is an autogenerated file for dynamic methods in `Post`.
              # Please instead update this file by running `bin/tapioca dsl Post`.

              class Post
                include SmartPropertiesGeneratedMethods

                sig { returns(T.untyped) }
                def custom_method; end

                module SmartPropertiesGeneratedMethods
                  sig { returns(T.nilable(::String)) }
                  def title; end

                  sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
                  def title=(title); end
                end
              end
            RBI
          end
        end

        describe "load non-rails app" do
          it "loads the app correctly with a custom loader" do
            @project.write("sorbet/tapioca/load.rb", <<~RB)
              Tapioca.load_for_dsl do
                print "Loading application..."
                require_relative "../../lib/post.rb"
                puts " Done"

                load_dsl_compilers
              end
            RB

            result = @project.tapioca("dsl Post")

            assert_includes(result.out, "Loading application... Done")
            assert_success_status(result)
            assert_project_file_exist("sorbet/rbi/dsl/post.rbi")
          end

          it "loads the app and custom compilers correctly with a custom loader" do
            @project.write("sorbet/tapioca/load.rb", <<~RB)
              Tapioca.load_for_dsl do
                print "Loading application..."
                require_relative "../../lib/post.rb"
                puts " Done"

                load_dsl_compilers
                require_relative "../../lib/compilers/custom_compiler.rb"
              end
            RB

            @project.write("lib/compilers/custom_compiler.rb", <<~RB)
              class CustomCompiler < Tapioca::Dsl::Compiler
                extend T::Sig

                ConstantType = type_member(fixed: T.class_of(::Post))

                sig { override.void }
                def decorate
                  root.create_path(constant) do |klass|
                    klass.create_method(:custom_method)
                  end
                end

                sig { override.returns(T::Enumerable[Module]) }
                def self.gather_constants
                  [::Post]
                end
              end
            RB

            result = @project.tapioca("dsl Post")

            @project.remove("lib/compilers/custom_compiler.rb")

            assert_includes(result.out, "Loading application... Done")
            assert_success_status(result)
            assert_project_file_equal("sorbet/rbi/dsl/post.rbi", <<~RBI)
              # typed: true

              # DO NOT EDIT MANUALLY
              # This is an autogenerated file for dynamic methods in `Post`.
              # Please instead update this file by running `bin/tapioca dsl Post`.

              class Post
                include SmartPropertiesGeneratedMethods

                sig { returns(T.untyped) }
                def custom_method; end

                module SmartPropertiesGeneratedMethods
                  sig { returns(T.nilable(::String)) }
                  def title; end

                  sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
                  def title=(title); end
                end
              end
            RBI
          end
        end
      end
    end
  end
end
