# typed: true
# frozen_string_literal: true

require "spec_helper"
require "ruby_lsp/tapioca/run_gem_rbi_check"

module Tapioca
  module RubyLsp
    class RunGemRbiCheckSpec < SpecWithProject
      FOO_RB = "module Foo; end"
      BAR_RB = "module Bar; end"

      before(:all) do
        @project = mock_project
      end

      describe "without git" do
        before do
          @project.bundle_install!
        end

        it "does nothing if there is no git repo" do
          foo = mock_gem("foo", "0.0.1") do
            write!("lib/foo.rb", FOO_RB)
          end
          @project.require_mock_gem(foo)

          @project.bundle_install!
          check = ::RubyLsp::Tapioca::RunGemRbiCheck.new(@project.absolute_path)
          check.run

          assert check.stdout.include?("Not a git repository")
        end
      end

      describe "with git" do
        before do
          FileUtils.mkdir_p("#{@project.absolute_path}/sorbet/rbi/gems")
          @project.write!("Gemfile", @project.tapioca_gemfile)
          @project.bundle_install!
          @project.exec("git init")
          @project.exec("git add .")
          @project.exec("git commit -m 'Initial commit'")
        end

        after do
          @project.remove!("sorbet/rbi")
          @project.remove!(".git")
          @project.remove!("Gemfile")
          @project.remove!("Gemfile.lock")
        end

        it "creates the RBI for a newly added gem" do
          foo = mock_gem("foo", "0.0.1") do
            write!("lib/foo.rb", FOO_RB)
          end
          @project.require_mock_gem(foo)
          @project.bundle_install!

          check = ::RubyLsp::Tapioca::RunGemRbiCheck.new(@project.absolute_path)
          check.run

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
        end

        it "regenerates RBI when a gem version changes" do
          foo = mock_gem("foo", "0.0.1") do
            write!("lib/foo.rb", FOO_RB)
          end
          @project.require_mock_gem(foo)
          @project.bundle_install!

          check = ::RubyLsp::Tapioca::RunGemRbiCheck.new(@project.absolute_path)
          check.run

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")

          # Modify the gem
          foo.update("0.0.2")
          @project.bundle_install!

          check.run

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.2.rbi")
        end

        it "removes RBI file when a gem is removed" do
          foo = mock_gem("foo", "0.0.1") do
            write!("lib/foo.rb", FOO_RB)
          end
          @project.require_mock_gem(foo)
          @project.bundle_install!

          check1 = ::RubyLsp::Tapioca::RunGemRbiCheck.new(@project.absolute_path)
          check1.run

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")

          @project.exec("git restore Gemfile Gemfile.lock")

          check2 = ::RubyLsp::Tapioca::RunGemRbiCheck.new(@project.absolute_path)
          check2.run

          refute_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
        end

        it "deletes untracked RBI files" do
          @project.bundle_install!
          # Create an untracked RBI file
          FileUtils.touch("#{@project.absolute_path}/sorbet/rbi/gems/bar@0.0.1.rbi")

          assert_project_file_exist("/sorbet/rbi/gems/bar@0.0.1.rbi")

          check = ::RubyLsp::Tapioca::RunGemRbiCheck.new(@project.absolute_path)
          check.run

          refute_project_file_exist("sorbet/rbi/gems/bar@0.0.1.rbi")
        end

        it "restores deleted RBI files" do
          @project.bundle_install!
          # Create and delete a tracked RBI file
          FileUtils.touch("#{@project.absolute_path}/sorbet/rbi/gems/foo@0.0.1.rbi")
          @project.exec("git add sorbet/rbi/gems/foo@0.0.1.rbi")
          @project.exec("git commit -m 'Add foo RBI'")
          FileUtils.rm("#{@project.absolute_path}/sorbet/rbi/gems/foo@0.0.1.rbi")

          refute_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")

          check = ::RubyLsp::Tapioca::RunGemRbiCheck.new(@project.absolute_path)
          check.run

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")

          # Clean-up commit
          @project.exec("git reset --hard HEAD^")
        end

        it "cleans up orphaned RBIs when gems are not present in the lockfile diff" do
          # Setup initial state
          foo = mock_gem("foo", "0.0.1") do
            write!("lib/foo.rb", FOO_RB)
          end
          bar = mock_gem("bar", "0.0.1") do
            write!("lib/bar.rb", BAR_RB)
          end
          @project.require_mock_gem(foo)
          @project.require_mock_gem(bar)
          @project.bundle_install!

          FileUtils.touch("#{@project.absolute_path}/sorbet/rbi/gems/foo@0.0.1.rbi")
          FileUtils.touch("#{@project.absolute_path}/sorbet/rbi/gems/bar@0.0.1.rbi")

          @project.exec("git add *")
          @project.exec("git commit -m 'Add foo and bar gems'")

          # Update both gems without committing

          foo.update("0.0.2")
          bar.update("0.0.2")
          @project.bundle_install!

          ::RubyLsp::Tapioca::RunGemRbiCheck.new(@project.absolute_path).run

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.2.rbi")
          assert_project_file_exist("sorbet/rbi/gems/bar@0.0.2.rbi")

          # Downgrade foo gem back to 0.0.1 which removes it from the git diff output

          foo.update("0.0.1")
          @project.bundle_install!

          refute_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")

          ::RubyLsp::Tapioca::RunGemRbiCheck.new(@project.absolute_path).run

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
        end
      end
    end
  end
end
