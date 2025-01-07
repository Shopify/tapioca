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

      # TODO: understand why this fails with `before(:all)`
      # before(:all) do
      before do
        @project.tapioca("configure")
      end

      after do
        project.write_gemfile!(project.tapioca_gemfile)
        @project.require_default_gems
        project.remove!("sorbet/rbi")
        project.remove!("../gems")
        project.remove!(".git")
        project.remove!("sorbet/tapioca/require.rb")
        project.remove!("config/application.rb")
      ensure
        @project.remove!("output")
      end

      def setup_git_repo
        @project.exec("git init")
        @project.exec("touch Gemfile.lock")
        FileUtils.mkdir_p("#{@project.absolute_path}/sorbet/rbi/gems")
        @project.exec("git add . && git commit -m 'Initial commit'")
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

      it "creates the RBI for a newly added gem" do
        setup_git_repo

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
        setup_git_repo

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
        setup_git_repo

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
        setup_git_repo

        # Create an untracked RBI file
        FileUtils.touch("#{@project.absolute_path}/sorbet/rbi/gems/bar@0.0.1.rbi")

        assert_project_file_exist("/sorbet/rbi/gems/bar@0.0.1.rbi")

        check = ::RubyLsp::Tapioca::RunGemRbiCheck.new
        check.run(@project.absolute_path)

        refute_project_file_exist("sorbet/rbi/gems/bar@0.0.1.rbi")
      end

      it "restores deleted RBI files" do
        setup_git_repo

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
  end
end
