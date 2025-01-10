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

      describe "without git" do
        before do
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
        # TODO: understand why this fails with `before(:all)`
        # before(:all) do
        before do
          @project.tapioca("configure")
          check_exec @project.exec("git init")
          check_exec @project.exec("git config user.email 'test@example.com'")
          check_exec @project.exec("git config user.name 'Test User'")
          @project.bundle_install!
          FileUtils.mkdir_p("#{@project.absolute_path}/sorbet/rbi/gems")
          check_exec @project.exec("git add .")
          check_exec @project.exec("git commit -m 'Initial commit'")
          $stdout.puts %x(cd #{@project.absolute_path} && git status)
        end

        after do
          ENV["BUNDLE_GEMFILE"] = nil
          @project.write_gemfile!(project.tapioca_gemfile)
          @project.require_default_gems
          @project.remove!("sorbet/rbi")
          @project.remove!("../gems")
          @project.remove!(".git")
          @project.remove!("sorbet/tapioca/require.rb")
          @project.remove!("config/application.rb")
          @project.remove!(".bundle")
          @project.remove!("Gemfile.lock")
        ensure
          @project.remove!("output")
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
          foo = mock_gem("foo", "0.0.2") do
            write!("lib/foo.rb", FOO_RB)
          end
          @project.require_mock_gem(foo)
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

          check = ::RubyLsp::Tapioca::RunGemRbiCheck.new
          check.run(@project.absolute_path)

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")

          @project.exec("git add Gemfile.lock")
          @project.exec("git commit -m 'Add foo gem'")

          @project.write_gemfile!(@project.tapioca_gemfile)
          @project.bundle_install!

          check = ::RubyLsp::Tapioca::RunGemRbiCheck.new
          check.run(@project.absolute_path)

          refute_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
        end

        it "deletes untracked RBI files" do
          # Create an untracked RBI file
          FileUtils.touch("#{@project.absolute_path}/sorbet/rbi/gems/bar@0.0.1.rbi")

          assert_project_file_exist("/sorbet/rbi/gems/bar@0.0.1.rbi")

          check = ::RubyLsp::Tapioca::RunGemRbiCheck.new
          check.run(@project.absolute_path)

          refute_project_file_exist("sorbet/rbi/gems/bar@0.0.1.rbi")
        end

        it "restores deleted RBI files" do
          # Create and delete a tracked RBI file
          FileUtils.touch("#{@project.absolute_path}/sorbet/rbi/gems/foo@0.0.1.rbi")
          @project.exec("git add sorbet/rbi/gems/foo@0.0.1.rbi")
          @project.exec("git commit -m 'Add foo RBI'")
          FileUtils.rm("#{@project.absolute_path}/sorbet/rbi/gems/foo@0.0.1.rbi")

          refute_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")

          check = ::RubyLsp::Tapioca::RunGemRbiCheck.new
          check.run(@project.absolute_path)

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
        end
      end

      def check_exec(command)
        result = command
        raise "fail" unless result.status
      end
    end
  end
end
