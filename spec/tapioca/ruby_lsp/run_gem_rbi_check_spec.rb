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

      it "does nothing if there is no git repo" do
        foo = mock_gem("foo", "0.0.1") do
          write!("lib/foo.rb", FOO_RB)
        end
        @project.require_mock_gem(foo)

        @project.bundle_install!
        check = ::RubyLsp::Tapioca::RunGemRbiCheck.new
        check.run(@project.absolute_path)

        assert check.logs.include?("Not a git repository")
      end

      it "create the RBI for a newly added gem" do
        @project.exec("git init")
        @project.exec("touch Gemfile.lock")
        @project.exec("git add . && git commit -m 'Initial commit'")

        foo = mock_gem("foo", "0.0.1") do
          write!("lib/foo.rb", FOO_RB)
        end
        @project.require_mock_gem(foo)
        @project.bundle_install!

        check = ::RubyLsp::Tapioca::RunGemRbiCheck.new
        check.run(@project.absolute_path)

        assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
      end
    end
  end
end
