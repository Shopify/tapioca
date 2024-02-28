# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  class RequireSpec < SpecWithProject
    describe "cli::require" do
      before(:all) do
        project.bundle_install!
        project.tapioca("configure")
      end

      after do
        @project.remove!("lib/")
        @project.remove!("test/")
        @project.remove!("sorbet/tapioca/require.rb")
      end

      it "does nothing if there is nothing to require" do
        result = @project.tapioca("require")

        assert_stdout_equals(<<~OUT, result)
          Compiling sorbet/tapioca/require.rb, this may take a few seconds... Nothing to do
        OUT

        assert_empty_stderr(result)
        assert_success_status(result)
      end

      it "creates a list of all requires from all Ruby files passed to Sorbet" do
        @project.write!("lib/foo.rb", <<~RB)
          require "found2"
          require "bar"
        RB

        @project.write!("lib/bar.rb", <<~RB)
          require "found1"
          require "foo"
        RB

        result = @project.tapioca("require")

        assert_stdout_equals(<<~OUT, result)
          Compiling sorbet/tapioca/require.rb, this may take a few seconds... Done
          All requires from this application have been written to sorbet/tapioca/require.rb.
          Please review changes and commit them, then run `bin/tapioca gem`.
        OUT

        assert_project_file_equal("sorbet/tapioca/require.rb", <<~RB)
          # typed: true
          # frozen_string_literal: true

          require "found1"
          require "found2"
        RB

        assert_empty_stderr(result)
        assert_success_status(result)
      end

      it "takes into account sorbet ignored paths" do
        @project.write!("lib/foo.rb", <<~RB)
          require "found2"
        RB

        @project.write!("lib/bar.rb", <<~RB)
          require "found1"
        RB

        @project.write!("test/foo_test.rb", <<~RB)
          require "not_found"
        RB

        @project.write_sorbet_config!(<<~CONFIG)
          .
          --ignore=test/
        CONFIG

        result = @project.tapioca("require")

        assert_stdout_equals(<<~OUT, result)
          Compiling sorbet/tapioca/require.rb, this may take a few seconds... Done
          All requires from this application have been written to sorbet/tapioca/require.rb.
          Please review changes and commit them, then run `bin/tapioca gem`.
        OUT

        assert_project_file_equal("sorbet/tapioca/require.rb", <<~RB)
          # typed: true
          # frozen_string_literal: true

          require "found1"
          require "found2"
        RB

        assert_empty_stderr(result)
        assert_success_status(result)
      end
    end
  end
end
