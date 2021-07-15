# typed: true
# frozen_string_literal: true

require_relative "../cli_spec"

module Tapioca
  class InitSpec < CliSpec
    describe("#init") do
      it "must create proper files" do
        FileUtils.rm_f(repo_path / "bin/tapioca")
        output = execute("init")

        assert_output(<<~OUTPUT, output)
          create  sorbet/config
          create  sorbet/tapioca/require.rb
          create  bin/tapioca
        OUTPUT

        assert_path_exists(repo_path / "sorbet/config")
        assert_equal(<<~CONTENTS, File.read(repo_path / "sorbet/config"))
          --dir
          .
        CONTENTS
        assert_path_exists(repo_path / "sorbet/tapioca/require.rb")
        assert_equal(<<~CONTENTS, File.read(repo_path / "sorbet/tapioca/require.rb"))
          # typed: true
          # frozen_string_literal: true

          # Add your extra requires here (`tapioca require` can be used to boostrap this list)
        CONTENTS

        assert_path_exists(repo_path / "bin/tapioca")
      end

      it "must not overwrite files" do
        FileUtils.mkdir_p(repo_path / "sorbet/tapioca")
        FileUtils.mkdir_p(repo_path / "bin")
        FileUtils.touch([
          repo_path / "bin/tapioca",
          repo_path / "sorbet/config",
          repo_path / "sorbet/tapioca/require.rb",
        ])

        output = execute("init")

        assert_output(<<~OUTPUT, output)
          skip  sorbet/config
          skip  sorbet/tapioca/require.rb
          force  bin/tapioca
        OUTPUT

        assert_empty(File.read(repo_path / "sorbet/config"))
        assert_empty(File.read(repo_path / "sorbet/tapioca/require.rb"))
      end
    end

    private

    def assert_output(expected, output)
      assert_equal(expected, output.lines.map(&:lstrip).join)
    end
  end
end
