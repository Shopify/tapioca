# typed: true
# frozen_string_literal: true

require "spec_helper"
require "ruby_lsp/tapioca/run_gem_rbi_check"

module Tapioca
  module RubyLsp
    class RunGemRbiCheckSpec < SpecWithProject
      FOO_RB = <<~RUBY
        module Foo
        end
      RUBY

      before do
        @project = mock_project
      end

      after do
        @project.destroy!
      end

      describe "without git" do
        before do
          @project.bundle_install!
          @project.tapioca("configure")
        end

        it "does nothing if there is no git repo" do
          foo = mock_gem("foo", "0.0.1") do
            write!("lib/foo.rb", FOO_RB)
          end
          @project.require_mock_gem(foo)

          @project.bundle_install!
          check = ::RubyLsp::Tapioca::RunGemRbiCheck.new
          check.run(@project.absolute_path)

          assert check.result.stdout.include?("Not a git repository")
        end
      end

      describe "with git" do
        before do
          @project.bundle_install!
          @project.tapioca("configure")
          @project.exec("git init")
          @project.exec("git config commit.gpgsign false")
          @project.exec("git add .")
          @project.exec("git commit -m 'Initial commit'")
        end

        it "creates the RBI for a newly added gem" do
          foo = mock_gem("foo", "0.0.1") do
            write!("lib/foo.rb", FOO_RB)
          end
          @project.require_mock_gem(foo)
          @project.bundle_install!

          check = ::RubyLsp::Tapioca::RunGemRbiCheck.new
          check.run(@project.absolute_path)

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
        end

        it "regenerates RBI when a gem version changes" do
          foo = mock_gem("foo", "0.0.1") do
            write!("lib/foo.rb", FOO_RB)
          end
          @project.require_mock_gem(foo)
          @project.bundle_install!

          check = ::RubyLsp::Tapioca::RunGemRbiCheck.new
          check.run(@project.absolute_path)

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")

          # Modify the gem
          update_gem foo, "0.0.2"
          @project.bundle_install!

          check.run(@project.absolute_path)

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.2.rbi")
        end

        it "removes RBI file when a gem is removed" do
          foo = mock_gem("foo", "0.0.1") do
            write!("lib/foo.rb", FOO_RB)
          end
          @project.require_mock_gem(foo)
          @project.bundle_install!

          check1 = ::RubyLsp::Tapioca::RunGemRbiCheck.new
          check1.run(@project.absolute_path)

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")

          @project.exec("git restore Gemfile Gemfile.lock")

          check2 = ::RubyLsp::Tapioca::RunGemRbiCheck.new
          check2.run(@project.absolute_path)

          refute_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
        end

        it "deletes untracked RBI files" do
          $stdout.puts @project.exec("git log --oneline")
          @project.bundle_install!
          FileUtils.mkdir_p("#{@project.absolute_path}/sorbet/rbi/gems")
          # Create an untracked RBI file
          FileUtils.touch("#{@project.absolute_path}/sorbet/rbi/gems/bar@0.0.1.rbi")

          assert_project_file_exist("/sorbet/rbi/gems/bar@0.0.1.rbi")

          check = ::RubyLsp::Tapioca::RunGemRbiCheck.new
          check.run(@project.absolute_path)

          refute_project_file_exist("sorbet/rbi/gems/bar@0.0.1.rbi")
        end

        it "restores deleted RBI files" do
          @project.bundle_install!
          FileUtils.mkdir_p("#{@project.absolute_path}/sorbet/rbi/gems")
          # Create and delete a tracked RBI file
          FileUtils.touch("#{@project.absolute_path}/sorbet/rbi/gems/foo@0.0.1.rbi")
          @project.exec("git add sorbet/rbi/gems/foo@0.0.1.rbi")
          @project.exec("git commit -m 'Add foo RBI'")
          FileUtils.rm("#{@project.absolute_path}/sorbet/rbi/gems/foo@0.0.1.rbi")
          $stdout.puts @project.exec("git log --oneline")

          refute_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")

          check = ::RubyLsp::Tapioca::RunGemRbiCheck.new
          check.run(@project.absolute_path)

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")

          # Clean-up commit
          @project.exec("git reset --hard HEAD^")
          $stdout.puts @project.exec("git log --oneline")
        end
      end
    end
  end
end