# typed: true
# frozen_string_literal: true

require "cli_spec"

module Tapioca
  class RequireSpec < CliSpec
    describe("#require") do
      before do
        tapioca("init")
      end

      it "does nothing if there is nothing to require" do
        File.write(repo_path / "sorbet/config", <<~CONFIG)
          .
          --ignore=postrequire.rb
          --ignore=postrequire_faulty.rb
          --ignore=config/
        CONFIG

        output = tapioca("require")

        assert_equal(<<~OUTPUT, output)
          Compiling sorbet/tapioca/require.rb, this may take a few seconds... Nothing to do
        OUTPUT

        assert_path_exists(repo_path / "sorbet/tapioca/require.rb")
        assert_equal(<<~CONTENTS, File.read(repo_path / "sorbet/tapioca/require.rb"))
          # typed: true
          # frozen_string_literal: true

          # Add your extra requires here (`bin/tapioca require` can be used to boostrap this list)
        CONTENTS
      end

      it "creates a list of all requires from all Ruby files passed to Sorbet" do
        output = tapioca("require")

        assert_equal(<<~OUTPUT, output)
          Compiling sorbet/tapioca/require.rb, this may take a few seconds... Done
          All requires from this application have been written to sorbet/tapioca/require.rb.
          Please review changes and commit them, then run `bin/tapioca gem`.
        OUTPUT

        assert_path_exists(repo_path / "sorbet/tapioca/require.rb")
        assert_equal(<<~CONTENTS, File.read(repo_path / "sorbet/tapioca/require.rb"))
          # typed: true
          # frozen_string_literal: true

          require "active_support/all"
          require "baz"
          require "foo/secret"
          require "foo/will_fail"
          require "rake"
          require "sidekiq"
          require "smart_properties"
        CONTENTS
      end

      it "takes into account sorbet ignored paths" do
        File.write(repo_path / "sorbet/config", <<~CONFIG)
          .
          --ignore=postrequire_faulty.rb
          --ignore=config/
        CONFIG

        output = tapioca("require")

        assert_equal(<<~OUTPUT, output)
          Compiling sorbet/tapioca/require.rb, this may take a few seconds... Done
          All requires from this application have been written to sorbet/tapioca/require.rb.
          Please review changes and commit them, then run `bin/tapioca gem`.
        OUTPUT

        assert_path_exists(repo_path / "sorbet/tapioca/require.rb")
        assert_equal(<<~CONTENTS, File.read(repo_path / "sorbet/tapioca/require.rb"))
          # typed: true
          # frozen_string_literal: true

          require "foo/secret"
        CONTENTS
      end
    end
  end
end
