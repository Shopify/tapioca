# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  class LoadSpec < SpecWithProject
    describe "cli::load" do
      # describe "generate gems" do
      #   describe "load rails app" do
      #   end

      #   describe "load non-rails app" do
      #     # case: rails app + gems
      #   end
      # end

      describe "generate dsl" do
        before(:all) do
          @project.require_real_gem("smart_properties", "1.15.0")
          @project.bundle_install

          @project.write("lib/post.rb", <<~RB)
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

        # it "must do the correct load stuff with custom loader" do
        #   @project.write("sorbet/tapioca/load.rb", <<~RB)
        #     Tapioca.load(:dsl) do
        #       load_for_dsl
        #     end
        #   RB
        # end

        describe "load rails app" do
          before(:all) do
            @project.write("config/application.rb", <<~RB)
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

            @project.write("config/environment.rb", <<~RB)
              require_relative "application.rb"
            RB
          end

          it "must load the app correctly in a default rails app" do
            result = @project.tapioca("dsl Post")
            assert_success_status(result)
            assert_project_file_exist("sorbet/rbi/dsl/post.rbi")
          end

          it "executes load.rb content if the file exists" do
            @project.write("sorbet/tapioca/load.rb", <<~RB)
              puts "Custom loader file loaded!"
              exit 0
            RB

            result = @project.tapioca("dsl Post")

            assert_includes(result.out, "Custom loader file loaded!")
            assert_success_status(result)
            refute_project_file_exist("sorbet/rbi/dsl/post.rbi")
          end

          it "lets load.rb errors propagate" do
            @project.write("sorbet/tapioca/load.rb", <<~RB)
              raise "Some kind of error!"
            RB

            result = @project.tapioca("dsl Post")

            assert_includes(result.err, "Some kind of error!")
            refute_success_status(result)
          end

          it "must load the app correctly in a default rails app with a custom loader" do
            @project.write("sorbet/tapioca/load.rb", <<~RB)
              Tapioca.load_for_dsl do
                load_dsl_extensions
                load_application(eager_load: @requested_constants.empty?)
                load_dsl_compilers
              end
            RB

            result = @project.tapioca("dsl Post")

            puts result
            assert_includes(result.out, "Loading Rails application... Done")
            assert_success_status(result)
            assert_project_file_exist("sorbet/rbi/dsl/post.rbi")
          end

          it "must load the app correctly in a default rails app with a custom loader using the default loader" do
            @project.write("sorbet/tapioca/load.rb", <<~RB)
              Tapioca.load_for_dsl do
                load_dsl_defaults
              end
            RB

            result = @project.tapioca("dsl Post")

            puts result
            assert_includes(result.out, "Loading Rails application... Done")
            assert_success_status(result)
            assert_project_file_exist("sorbet/rbi/dsl/post.rbi")
          end

          #   # case: rails app + dsl
          #   # case: rails app + dsl + custom generator
          #   # case: rails app + dsl + custom ext
        end

        # describe "load non-rails app" do
        #   # case: non-rails app + dsl
        #   # case: non-rails app + dsl + custom generator
        #   # case: non-rails app + dsl + custom ext
        # end
      end
    end
  end
end
