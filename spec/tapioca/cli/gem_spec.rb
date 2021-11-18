# typed: true
# frozen_string_literal: true

require "spec_with_project"
require "tapioca/helpers/test/template"

module Tapioca
  class GemSpec < SpecWithProject
    include Tapioca::Helpers::Test::Template

    FOO_RB = <<~RB
      module Foo
        PI = 3.1415

        def self.bar(a = 1, b: 2, **opts)
          number = opts[:number] || 0
          39 + a + b + number
        end
      end
    RB

    FOO_RBI = <<~RBI
      # typed: true

      # DO NOT EDIT MANUALLY
      # This is an autogenerated file for types exported from the `foo` gem.
      # Please instead update this file by running `bin/tapioca gem foo`.

      module Foo
        class << self
          def bar(a = T.unsafe(nil), b: T.unsafe(nil), **opts); end
        end
      end

      Foo::PI = T.let(T.unsafe(nil), Float)
    RBI

    BAR_RB = <<~RB
      module Bar
        PI = 3.1415

        def self.bar(a = 1, b: 2, **opts)
          number = opts[:number] || 0
          39 + a + b + number
        end
      end
    RB

    BAR_RBI = <<~RBI
      # typed: true

      # DO NOT EDIT MANUALLY
      # This is an autogenerated file for types exported from the `bar` gem.
      # Please instead update this file by running `bin/tapioca gem bar`.

      module Bar
        class << self
          def bar(a = T.unsafe(nil), b: T.unsafe(nil), **opts); end
        end
      end

      Bar::PI = T.let(T.unsafe(nil), Float)
    RBI

    BAZ_RB = <<~RB
      module Baz
        class Test
          def fizz
            "abc" * 10
          end
        end
      end
    RB

    BAZ_RBI = <<~RBI
      # typed: true

      # DO NOT EDIT MANUALLY
      # This is an autogenerated file for types exported from the `baz` gem.
      # Please instead update this file by running `bin/tapioca gem baz`.

      module Baz; end

      class Baz::Test
        def fizz; end
      end
    RBI

    describe("#cli::gem") do
      before(:all) do
        @project.bundle_install
      end

      describe("flags") do
        it "must show an error if --all is supplied with arguments" do
          out, err, status = @project.tapioca("gem --all foo")

          assert_equal(<<~ERR, err)
            Option '--all' must be provided without any other arguments
          ERR

          assert_empty(out)
          refute(status)
        end

        it "must show an error if --verify is supplied with arguments" do
          out, err, status = @project.tapioca("gem --verify foo")

          assert_equal(<<~ERR, err)
            Option '--verify' must be provided without any other arguments
          ERR

          assert_empty(out)
          refute(status)
        end

        it "must show an error if both --all and --verify are supplied" do
          out, err, status = @project.tapioca("gem --all --verify")

          assert_equal(<<~ERR, err)
            Options '--all' and '--verify' are mutually exclusive
          ERR

          assert_empty(out)
          refute(status)
        end
      end

      describe("generate") do
        before(:all) do
          @project.tapioca("init")
        end

        after do
          project.gemfile(project.tapioca_gemfile)
          project.remove("sorbet/rbi")
          project.remove("../gems")
        end

        it "must generate a single gem RBI" do
          foo = mock_gem("foo", "0.0.1") do
            write("lib/foo.rb", FOO_RB)
          end

          bar = mock_gem("bar", "0.3.0") do
            write("lib/bar.rb", BAR_RB)
          end

          @project.gemfile(<<~GEMFILE, append: true)
            #{foo.gemfile_line}
            #{bar.gemfile_line}
          GEMFILE

          @project.bundle_install

          out, err, status = @project.tapioca("gem foo")

          assert_includes(out, <<~OUT)
            Compiled foo
                  create  sorbet/rbi/gems/foo@0.0.1.rbi
          OUT

          assert_project_file_equal("sorbet/rbi/gems/foo@0.0.1.rbi", FOO_RBI)
          refute_project_file_exist("sorbet/rbi/gems/bar@0.3.0.rbi")

          assert_empty(err)
          assert(status)
        end

        it "must generate RBI for a default gem" do
          @project.require_real_gem("did_you_mean", "= 1.5.0")
          @project.bundle_install

          out, err, status = @project.tapioca("gem did_you_mean")

          assert_includes(out, <<~OUT)
            Compiled did_you_mean
                  create  sorbet/rbi/gems/did_you_mean@1.5.0.rbi
          OUT

          assert_includes(@project.read("sorbet/rbi/gems/did_you_mean@1.5.0.rbi"), "module DidYouMean")

          assert_empty(err)
          assert(status)
        end

        it "must generate gem RBI in correct output directory" do
          foo = mock_gem("foo", "0.0.1") do
            write("lib/foo.rb", FOO_RB)
          end

          @project.require_mock_gem(foo)
          @project.bundle_install

          out, err, status = @project.tapioca("gem foo --outdir rbis/")

          assert_includes(out, <<~OUT)
            Compiled foo
          OUT

          assert_project_file_equal("rbis/foo@0.0.1.rbi", FOO_RBI)

          assert_empty(err)
          assert(status)

          @project.remove("rbis/")
        end

        it "must remove outdated RBIs" do
          @project.require_mock_gem(mock_gem("foo", "0.0.1"))
          @project.require_mock_gem(mock_gem("bar", "0.3.0"))
          @project.require_mock_gem(mock_gem("baz", "0.0.2"))
          @project.bundle_install

          @project.write("sorbet/rbi/gems/foo@0.0.1.rbi")
          @project.write("sorbet/rbi/gems/bar@0.3.0.rbi")
          @project.write("sorbet/rbi/gems/baz@0.0.2.rbi")
          @project.write("sorbet/rbi/gems/outdated@5.0.0.rbi")

          out, err, status = @project.tapioca("gem --all")

          assert_includes(out, "remove  sorbet/rbi/gems/outdated@5.0.0.rbi\n")
          refute_includes(out, "create sorbet/rbi/gems/foo@0.0.1.rbi")
          refute_includes(out, "create sorbet/rbi/gems/bar@0.3.0.rbi")
          refute_includes(out, "create sorbet/rbi/gems/baz@0.0.2.rbi")
          refute_includes(out, "-> Moving:")

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
          assert_project_file_exist("sorbet/rbi/gems/bar@0.3.0.rbi")
          assert_project_file_exist("sorbet/rbi/gems/baz@0.0.2.rbi")
          refute_project_file_exist("sorbet/rbi/gems/outdated@5.0.0.rbi")

          assert_empty(err)
          assert(status)
        end

        it "must perform postrequire properly" do
          foo = mock_gem("foo", "0.0.1") do
            write("lib/foo.rb", FOO_RB)
            write("lib/foo/secret.rb", "class Foo::Secret; end")
          end

          @project.require_mock_gem(foo)
          @project.bundle_install

          @project.write("sorbet/tapioca/require.rb", <<~RB)
            require "foo/secret"
          RB

          out, err, status = @project.tapioca("gem foo")

          assert_includes(out, <<~OUT)
            Compiled foo
          OUT

          assert_project_file_equal("sorbet/rbi/gems/foo@0.0.1.rbi", template(<<~RBI))
            #{FOO_RBI.rstrip}
            class Foo::Secret; end
          RBI

          assert_empty(err)
          assert(status)

          @project.remove("sorbet/tapioca/require.rb")
        end

        it "explains what went wrong when it can't load the postrequire properly" do
          foo = mock_gem("foo", "0.0.1") do
            write("lib/foo.rb", FOO_RB)
          end

          @project.require_mock_gem(foo)
          @project.bundle_install

          @project.write("sorbet/tapioca/require.rb", <<~RB)
            require "foo/will_fail"
          RB

          _, err, status = @project.tapioca("gem foo")

          assert_includes(err, <<~ERR)
            LoadError: cannot load such file -- foo/will_fail

            Tapioca could not load all the gems required by your application.
            If you populated sorbet/tapioca/require.rb with `bin/tapioca require`
            you should probably review it and remove the faulty line.
          ERR

          refute(status)

          @project.remove("sorbet/tapioca/require.rb")
        end

        it "must not include `rbi` definitions into `tapioca` RBI" do
          out, err, status = @project.tapioca("gem tapioca")

          assert_includes(out, <<~OUT)
            Compiled tapioca
          OUT

          tapioca_rbi_file = T.must(Dir.glob("#{@project.path}/sorbet/rbi/gems/tapioca@*.rbi").first)
          refute_includes(File.read(tapioca_rbi_file), "class RBI::Module")

          assert_empty(err)
          assert(status)
        end

        it "must generate multiple gem RBIs" do
          foo = mock_gem("foo", "0.0.1") do
            write("lib/foo.rb", FOO_RB)
          end

          bar = mock_gem("bar", "0.3.0") do
            write("lib/bar.rb", BAR_RB)
          end

          baz = mock_gem("baz", "0.0.2") do
            write("lib/baz.rb", BAZ_RB)
          end

          @project.require_mock_gem(foo)
          @project.require_mock_gem(bar)
          @project.require_mock_gem(baz)
          @project.bundle_install

          out, err, status = @project.tapioca("gem foo bar")

          assert_includes(out, "Compiled foo")
          assert_includes(out, "Compiled bar")
          assert_project_file_equal("sorbet/rbi/gems/foo@0.0.1.rbi", FOO_RBI)
          assert_project_file_equal("sorbet/rbi/gems/bar@0.3.0.rbi", BAR_RBI)
          refute_project_file_exist("sorbet/rbi/gems/baz@0.0.2.rbi")

          assert_empty(err)
          assert(status)
        end

        it "must generate RBIs for all gems in the Gemfile" do
          foo = mock_gem("foo", "0.0.1") do
            write("lib/foo.rb", FOO_RB)
          end

          bar = mock_gem("bar", "0.3.0") do
            write("lib/bar.rb", BAR_RB)
          end

          baz = mock_gem("baz", "0.0.2") do
            write("lib/baz.rb", BAZ_RB)
          end

          @project.require_mock_gem(foo)
          @project.require_mock_gem(bar)
          @project.require_mock_gem(baz)
          @project.bundle_install

          out, err, status = @project.tapioca("gem --all")

          assert_includes(out, "Compiled bar")
          assert_includes(out, "Compiled baz")
          assert_includes(out, "Compiled foo")

          assert_project_file_equal("sorbet/rbi/gems/foo@0.0.1.rbi", FOO_RBI)
          assert_project_file_equal("sorbet/rbi/gems/bar@0.3.0.rbi", BAR_RBI)
          assert_project_file_equal("sorbet/rbi/gems/baz@0.0.2.rbi", BAZ_RBI)

          assert_empty(err)
          assert(status)
        end

        it "must not generate RBIs for missing gem specs" do
          @project.gemfile(<<~GEMFILE, append: true)
            gem "minitest"

            platform :truffleruby do
              gem "minitest-excludes"
            end
          GEMFILE

          @project.bundle_install

          out, err, status = @project.tapioca("gem --all")

          puts out

          assert_includes(out, "completed with missing specs: minitest-excludes (2.0.1)")
          refute_includes(out, "Compiling minitest-excludes, this may take a few seconds")

          assert_empty(err)
          assert(status)
        end

        it "must generate git gem RBIs with source revision numbers" do
          @project.gemfile(<<~GEMFILE, append: true)
            gem("ast", git: "https://github.com/whitequark/ast", ref: "e07a4f66e05ac7972643a8841e336d327ea78ae1")
          GEMFILE

          @project.bundle_install

          out, err, status = @project.tapioca("gem ast")

          assert_includes(out, "Compiled ast")

          assert_project_file_exist("sorbet/rbi/gems/ast@2.4.1-e07a4f66e05ac7972643a8841e336d327ea78ae1.rbi")

          assert_empty(err)
          assert(status)
        end

        it "must respect exclude option" do
          @project.require_mock_gem(mock_gem("foo", "0.0.1"))
          @project.require_mock_gem(mock_gem("bar", "0.3.0"))
          @project.require_mock_gem(mock_gem("baz", "0.0.2"))
          @project.bundle_install

          out, err, status = @project.tapioca("gem --all --exclude foo bar")

          refute_includes(out, "Compiled bar")
          assert_includes(out, "Compiled baz")
          refute_includes(out, "Compiled foo")

          refute_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
          refute_project_file_exist("sorbet/rbi/gems/bar@0.3.0.rbi")
          assert_project_file_exist("sorbet/rbi/gems/baz@0.0.2.rbi")

          assert_empty(err)
          assert(status)
        end

        it "does not crash when the extras gem is loaded" do
          foo = mock_gem("foo", "0.0.1") do
            write("lib/foo.rb", FOO_RB)
          end

          @project.require_real_gem("extras")
          @project.require_mock_gem(foo)
          @project.bundle_install

          @project.write("sorbet/tapioca/require.rb", <<~RB)
            require "extras/shell"
          RB

          out, err, status = @project.tapioca("gem foo")

          assert_includes(out, "Compiled foo")
          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
          assert_project_file_equal("sorbet/rbi/gems/foo@0.0.1.rbi", FOO_RBI)

          assert_empty(err)
          assert(status)

          @project.remove("sorbet/tapioca/require.rb")
        end

        it "generate an empty RBI file" do
          @project.require_mock_gem(mock_gem("foo", "0.0.1"))
          @project.bundle_install

          out, err, status = @project.tapioca("gem foo")

          assert_includes(out, "Compiled foo (empty output)")
          assert_includes(out, "create  sorbet/rbi/gems/foo@0.0.1.rbi\n")

          assert_project_file_equal("sorbet/rbi/gems/foo@0.0.1.rbi", <<~RBI)
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for types exported from the `foo` gem.
            # Please instead update this file by running `bin/tapioca gem foo`.

            # THIS IS AN EMPTY RBI FILE.
            # see https://github.com/Shopify/tapioca/wiki/Manual-Gem-Requires
          RBI

          assert_empty(err)
          assert(status)
        end

        it "generate an empty RBI file without header" do
          @project.require_mock_gem(mock_gem("foo", "0.0.1"))
          @project.bundle_install

          _, err, status = @project.tapioca("gem foo --no-file-header")

          assert_project_file_equal("sorbet/rbi/gems/foo@0.0.1.rbi", <<~RBI)
            # typed: true

            # THIS IS AN EMPTY RBI FILE.
            # see https://github.com/Shopify/tapioca/wiki/Manual-Gem-Requires
          RBI

          assert_empty(err)
          assert(status)
        end

        it "generates the correct RBIs when running generate in parallel" do
          @project.require_mock_gem(mock_gem("foo", "0.0.1"))
          @project.require_mock_gem(mock_gem("bar", "0.3.0"))
          @project.require_mock_gem(mock_gem("baz", "0.0.2"))
          @project.bundle_install

          _, err, status = @project.tapioca("gem --all --workers 3")

          assert_empty(err)
          assert(status)

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
          assert_project_file_exist("sorbet/rbi/gems/bar@0.3.0.rbi")
          assert_project_file_exist("sorbet/rbi/gems/baz@0.0.2.rbi")
        end

        it "generates abstract classes properly" do
          foo = mock_gem("foo", "0.0.1") do
            write("lib/foo.rb", <<~RB)
              class Foo
                extend T::Sig
                extend T::Helpers

                abstract!

                sig { abstract.void }
                def foo; end

                sig { abstract.void }
                def self.foo; end

                class Bar
                  extend T::Sig
                  extend T::Helpers

                  abstract!

                  sig { abstract.returns(String) }
                  def bar; end
                end
              end
            RB
          end

          @project.require_mock_gem(foo)
          @project.bundle_install

          _, err, status = @project.tapioca("gem foo")

          assert_empty(err)
          assert(status)

          assert_project_file_equal("sorbet/rbi/gems/foo@0.0.1.rbi", <<~RBI)
            # typed: true

            # DO NOT EDIT MANUALLY
            # This is an autogenerated file for types exported from the `foo` gem.
            # Please instead update this file by running `bin/tapioca gem foo`.

            class Foo
              abstract!

              def initialize(*args, &blk); end

              sig { abstract.void }
              def foo; end

              class << self
                sig { abstract.void }
                def foo; end
              end
            end

            class Foo::Bar
              abstract!

              def initialize(*args, &blk); end

              sig { abstract.returns(String) }
              def bar; end
            end
          RBI
        end
      end

      describe("sync") do
        before(:all) do
          @project.require_mock_gem(mock_gem("foo", "0.0.1"))
          @project.require_mock_gem(mock_gem("bar", "0.3.0"))
          @project.require_mock_gem(mock_gem("baz", "0.0.2"))
          @project.bundle_install
        end

        after do
          @project.remove("sorbet/rbi/gems")
        end

        after(:all) do
          @project.remove("../gems")
        end

        it "must perform no operations if everything is up-to-date" do
          @project.write("sorbet/rbi/gems/foo@0.0.1.rbi")
          @project.write("sorbet/rbi/gems/bar@0.3.0.rbi")
          @project.write("sorbet/rbi/gems/baz@0.0.2.rbi")

          out, err, status = @project.tapioca("gem")

          refute_includes(out, "remove ")
          refute_includes(out, "create sorbet/rbi/gems/foo@0.0.1.rb")
          refute_includes(out, "create sorbet/rbi/gems/bar@0.3.0.rb")
          refute_includes(out, "create sorbet/rbi/gems/baz@0.0.2.rb")
          refute_includes(out, "-> Moving:")

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
          assert_project_file_exist("sorbet/rbi/gems/bar@0.3.0.rbi")
          assert_project_file_exist("sorbet/rbi/gems/baz@0.0.2.rbi")

          assert_empty(err)
          assert(status)
        end

        it "must respect exclude option" do
          @project.write("sorbet/rbi/gems/foo@0.0.1.rbi")
          @project.write("sorbet/rbi/gems/bar@0.3.0.rbi")
          @project.write("sorbet/rbi/gems/baz@0.0.2.rbi")

          out, err, status = @project.tapioca("gem --exclude foo bar")

          assert_includes(out, "remove  sorbet/rbi/gems/foo@0.0.1.rbi\n")
          assert_includes(out, "remove  sorbet/rbi/gems/bar@0.3.0.rbi\n")
          refute_includes(out, "remove  sorbet/rbi/gems/baz@0.0.2.rbi\n")
          refute_includes(out, "create sorbet/rbi/gems/foo@0.0.1.rbi")
          refute_includes(out, "create sorbet/rbi/gems/bar@0.3.0.rbi")
          refute_includes(out, "create sorbet/rbi/gems/baz@0.0.2.rbi")
          refute_includes(out, "-> Moving:")

          refute_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
          refute_project_file_exist("sorbet/rbi/gems/bar@0.3.0.rbi")
          assert_project_file_exist("sorbet/rbi/gems/baz@0.0.2.rbi")

          assert_empty(err)
          assert(status)
        end

        it "must remove outdated RBIs" do
          @project.write("sorbet/rbi/gems/foo@0.0.1.rbi")
          @project.write("sorbet/rbi/gems/bar@0.3.0.rbi")
          @project.write("sorbet/rbi/gems/baz@0.0.2.rbi")
          @project.write("sorbet/rbi/gems/outdated@5.0.0.rbi")

          out, err, status = @project.tapioca("gem")

          assert_includes(out, "remove  sorbet/rbi/gems/outdated@5.0.0.rbi\n")
          refute_includes(out, "create sorbet/rbi/gems/foo@0.0.1.rbi")
          refute_includes(out, "create sorbet/rbi/gems/bar@0.3.0.rbi")
          refute_includes(out, "create sorbet/rbi/gems/baz@0.0.2.rbi")
          refute_includes(out, "-> Moving:")

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
          assert_project_file_exist("sorbet/rbi/gems/bar@0.3.0.rbi")
          assert_project_file_exist("sorbet/rbi/gems/baz@0.0.2.rbi")
          refute_project_file_exist("sorbet/rbi/gems/outdated@5.0.0.rbi")

          assert_empty(err)
          assert(status)
        end

        it "must add missing RBIs" do
          @project.write("sorbet/rbi/gems/foo@0.0.1.rbi")

          out, err, status = @project.tapioca("gem")

          assert_includes(out, "create  sorbet/rbi/gems/bar@0.3.0.rbi\n")
          assert_includes(out, "create  sorbet/rbi/gems/baz@0.0.2.rbi\n")
          refute_includes(out, "remove ")
          refute_includes(out, "-> Moving:")

          assert_includes(out, <<~OUT)
            Removing RBI files of gems that have been removed:

              Nothing to do.
          OUT

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
          assert_project_file_exist("sorbet/rbi/gems/bar@0.3.0.rbi")
          assert_project_file_exist("sorbet/rbi/gems/baz@0.0.2.rbi")

          assert_empty(err)
          assert(status)
        end

        it "must move outdated RBIs" do
          @project.write("sorbet/rbi/gems/foo@0.0.1.rbi")
          @project.write("sorbet/rbi/gems/bar@0.0.1.rbi")
          @project.write("sorbet/rbi/gems/baz@0.0.1.rbi")

          out, err, status = @project.tapioca("gem")

          assert_includes(out, "-> Moving: sorbet/rbi/gems/bar@0.0.1.rbi to sorbet/rbi/gems/bar@0.3.0.rbi\n")
          assert_includes(out, "force  sorbet/rbi/gems/bar@0.3.0.rbi\n")
          assert_includes(out, "-> Moving: sorbet/rbi/gems/baz@0.0.1.rbi to sorbet/rbi/gems/baz@0.0.2.rbi\n")
          assert_includes(out, "force  sorbet/rbi/gems/baz@0.0.2.rbi\n")
          refute_includes(out, "remove ")

          assert_includes(out, <<~OUT)
            Removing RBI files of gems that have been removed:

              Nothing to do.
          OUT

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
          assert_project_file_exist("sorbet/rbi/gems/bar@0.3.0.rbi")
          assert_project_file_exist("sorbet/rbi/gems/baz@0.0.2.rbi")

          refute_project_file_exist("sorbet/rbi/gems/bar@0.0.1.rbi")
          refute_project_file_exist("sorbet/rbi/gems/baz@0.0.1.rbi")

          assert_empty(err)
          assert(status)
        end

        it "generates the correct RBIs when running sync in parallel" do
          _, err, status = @project.tapioca("gem --workers 3")

          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
          assert_project_file_exist("sorbet/rbi/gems/bar@0.3.0.rbi")
          assert_project_file_exist("sorbet/rbi/gems/baz@0.0.2.rbi")

          assert_empty(err)
          assert(status)
        end
      end

      describe("verify") do
        before(:all) do
          @project.require_mock_gem(mock_gem("foo", "0.0.1"))
          @project.require_mock_gem(mock_gem("bar", "0.3.0"))
          @project.bundle_install
        end

        after(:all) do
          @project.remove("../gems")
        end

        it "does nothing and returns exit_status 0 when nothing changes" do
          @project.tapioca("gem")

          out, err, status = @project.tapioca("gem --verify")

          assert_equal(<<~OUT, out)
            Checking for out-of-date RBIs...

            Nothing to do, all RBIs are up-to-date.
          OUT

          assert_empty(err)
          assert(status)
        end

        it "advises of removed file(s) and returns exit_status 1" do
          @project.tapioca("gem")

          out, err, status = @project.tapioca("gem --verify --exclude foo bar")

          assert_equal(<<~OUT, out)
            Checking for out-of-date RBIs...

            RBI files are out-of-date. In your development environment, please run:
              `bin/tapioca gem`
            Once it is complete, be sure to commit and push any changes

            Reason:
              File(s) removed:
              - sorbet/rbi/gems/bar@0.3.0.rbi
              - sorbet/rbi/gems/foo@0.0.1.rbi
          OUT

          # Does not actually modify anything
          assert_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
          assert_project_file_exist("sorbet/rbi/gems/bar@0.3.0.rbi")

          assert_empty(err)
          refute(status)
        end

        it "advises of added/removed/changed file(s) and returns exit_status 1" do
          @project.tapioca("gem")

          @project.remove("sorbet/rbi/gems/foo@0.0.1.rbi")
          @project.write("sorbet/rbi/gems/outdated@5.0.0.rbi")
          @project.move("sorbet/rbi/gems/bar@0.3.0.rbi", "sorbet/rbi/gems/bar@0.2.0.rbi")

          out, err, status = @project.tapioca("gem --verify")

          assert_equal(<<~OUT, out)
            Checking for out-of-date RBIs...

            RBI files are out-of-date. In your development environment, please run:
              `bin/tapioca gem`
            Once it is complete, be sure to commit and push any changes

            Reason:
              File(s) added:
              - sorbet/rbi/gems/foo@0.0.1.rbi
              File(s) changed:
              - sorbet/rbi/gems/bar@0.3.0.rbi
              File(s) removed:
              - sorbet/rbi/gems/outdated@5.0.0.rbi
          OUT

          # Does not actually modify anything
          refute_project_file_exist("sorbet/rbi/gems/foo@0.0.1.rbi")
          assert_project_file_exist("sorbet/rbi/gems/outdated@5.0.0.rbi")
          assert_project_file_exist("sorbet/rbi/gems/bar@0.2.0.rbi")

          assert_empty(err)
          refute(status)
        end
      end
    end
  end
end
