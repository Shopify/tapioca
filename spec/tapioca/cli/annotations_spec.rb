# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  class AnnotationsTest < SpecWithProject
    describe "cli::annotations" do
      before(:all) do
        @project.bundle_install!
      end

      after do
        @project.remove!("sorbet/rbi/annotations")
      end

      it "does nothing if the repo is empty" do
        repo = create_repo({})

        result = @project.tapioca("annotations --sources #{repo.absolute_path}")

        assert_equal(<<~OUT, result.out)
          Retrieving index from central repository... Done
          Listing gems from Gemfile.lock... Done
          Removing annotations for gems that have been removed...  Nothing to do
          Fetching gem annotations from central repository...  Nothing to do
        OUT

        assert_success_status(result)
        refute(File.directory?(@project.absolute_path_to("sorbet/rbi/annotations")))

        repo.destroy!
      end

      it "removes local annotations if they do not appear in the Gemfile.lock" do
        repo = create_repo({})

        @project.write!("sorbet/rbi/annotations/rbi.rbi", "# typed: true")
        @project.write!("sorbet/rbi/annotations/bar.rbi", "# typed: true")
        @project.write!("sorbet/rbi/annotations/foo.rbi", "# typed: true")

        result = @project.tapioca("annotations --sources #{repo.absolute_path}")

        assert_stdout_includes(result, "remove  sorbet/rbi/annotations/bar.rbi")
        assert_stdout_includes(result, "remove  sorbet/rbi/annotations/foo.rbi")
        refute_includes(result.out, "remove  sorbet/rbi/annotations/rbi.rbi")

        assert_success_status(result)

        repo.destroy!
      end

      it "gets annotations from the central repo" do
        repo = create_repo({
          rbi: <<~RBI,
            # typed: true

            class AnnotationForRBI; end
          RBI
          spoom: <<~RBI,
            # typed: strict

            class AnnotationForSpoom; end
          RBI
          foo: <<~RBI,
            # typed: false

            class AnnotationForFoo; end
          RBI
        })

        result = @project.tapioca("annotations --sources #{repo.absolute_path}")

        assert_stdout_includes(result, "create  sorbet/rbi/annotations/rbi.rbi")
        assert_stdout_includes(result, "create  sorbet/rbi/annotations/spoom.rbi")
        refute_includes(result.out, "create  sorbet/rbi/annotations/foo.rbi")

        assert_project_annotation_equal("sorbet/rbi/annotations/rbi.rbi", <<~RBI)
          # typed: true

          # DO NOT EDIT MANUALLY
          # This file was pulled from a central RBI files repository.
          # Please run `bin/tapioca annotations` to update it.

          class AnnotationForRBI; end
        RBI

        assert_project_annotation_equal("sorbet/rbi/annotations/spoom.rbi", <<~RBI)
          # typed: strict

          # DO NOT EDIT MANUALLY
          # This file was pulled from a central RBI files repository.
          # Please run `bin/tapioca annotations` to update it.

          class AnnotationForSpoom; end
        RBI

        assert_project_file_equal("sorbet/rbi/annotations/.gitattributes", <<~CONTENT)
          **/*.rbi linguist-vendored=true
        CONTENT
        refute_project_file_exist("sorbet/rbi/annotations/foo.rbi")
        assert_success_status(result)

        repo.destroy!
      end

      it "gets index from the central repo using the default source" do
        result = @project.tapioca("annotations")

        assert_stdout_includes(result, "Retrieving index from central repository... Done")
        assert_success_status(result)
      end

      it "recovers from a bad source" do
        result = @project.tapioca("annotations --sources #{Tapioca::CENTRAL_REPO_ROOT_URI} https://bad-source")

        assert_stdout_includes(result, "Retrieving index from central repository #1... Done")
        assert_stderr_includes(result, "Can't fetch file `index.json` from https://bad-source")
        assert_stderr_includes(result, <<~ERROR)
          Tapioca can't access the annotations at https://bad-source.

          Are you trying to access a private repository?
          If so, please specify your Github credentials in your ~/.netrc file or by specifying the --auth option.

          See https://github.com/Shopify/tapioca#using-a-netrc-file for more details.
        ERROR
        assert_success_status(result)
      end

      it "errors without a valid source" do
        result = @project.tapioca("annotations --sources https://bad-source")

        assert_stderr_includes(result, "Can't fetch file `index.json` from https://bad-source")
        assert_stderr_includes(result, "Can't fetch annotations without sources (no index fetched)")
        refute_success_status(result)
      end

      it "handles parse errors within annotations" do
        repo = create_repo({
          spoom: <<~RBI,
            # typed: true

            class AnnotationForSpoom
          RBI
        })

        result = @project.tapioca("annotations --sources #{repo.absolute_path}")

        assert_stderr_includes(result, <<~ERR)
          Can't import RBI file for `spoom` as it contains errors:
              Error: Cannot parse the expression. Expected an `end` to close the `class` statement. (-:4:0)
        ERR

        refute_includes(result.out, "create  sorbet/rbi/annotations/spoom.rbi")
        refute_project_file_exist("sorbet/rbi/annotations/spoom.rbi")

        repo.destroy!
      end

      it "gets annotations from multiple repos" do
        repo1 = create_repo(
          {
            rbi: <<~RBI,
              # typed: true

              class AnnotationForRBI; end
            RBI
          },
          repo_name: "repo1",
        )

        repo2 = create_repo(
          {
            spoom: <<~RBI,
              # typed: strict

              class AnnotationForSpoom; end
            RBI
          },
          repo_name: "repo2",
        )

        result = @project.tapioca("annotations --sources #{repo1.absolute_path} #{repo2.absolute_path}")

        assert_stdout_includes(result, "create  sorbet/rbi/annotations/rbi.rbi")
        assert_stdout_includes(result, "create  sorbet/rbi/annotations/spoom.rbi")

        assert_project_annotation_equal("sorbet/rbi/annotations/rbi.rbi", <<~RBI)
          # typed: true

          # DO NOT EDIT MANUALLY
          # This file was pulled from a central RBI files repository.
          # Please run `bin/tapioca annotations` to update it.

          class AnnotationForRBI; end
        RBI

        assert_project_annotation_equal("sorbet/rbi/annotations/spoom.rbi", <<~RBI)
          # typed: strict

          # DO NOT EDIT MANUALLY
          # This file was pulled from a central RBI files repository.
          # Please run `bin/tapioca annotations` to update it.

          class AnnotationForSpoom; end
        RBI

        assert_success_status(result)

        repo1.destroy!
        repo2.destroy!
      end

      it "merges annotations from multiple repos" do
        repo1 = create_repo(
          {
            rbi: <<~RBI,
              # typed: true

              class AnnotationForRBI
                def foo; end
                def bar; end
              end
            RBI
          },
          repo_name: "repo1",
        )

        repo2 = create_repo(
          {
            rbi: <<~RBI,
              # typed: true

              class AnnotationForRBI
                def foo; end
                def baz; end
              end
            RBI
          },
          repo_name: "repo2",
        )

        result = @project.tapioca("annotations --sources #{repo1.absolute_path} #{repo2.absolute_path}")

        assert_stdout_includes(result, "create  sorbet/rbi/annotations/rbi.rbi")

        assert_project_annotation_equal("sorbet/rbi/annotations/rbi.rbi", <<~RBI)
          # typed: true

          # DO NOT EDIT MANUALLY
          # This file was pulled from a central RBI files repository.
          # Please run `bin/tapioca annotations` to update it.

          class AnnotationForRBI
            def foo; end
            def bar; end
            def baz; end
          end
        RBI

        assert_success_status(result)

        repo1.destroy!
        repo2.destroy!
      end

      it "handles conflicts with annotations from multiple repos" do
        repo1 = create_repo(
          {
            spoom: <<~RBI,
              # typed: true

              class AnnotationForSpoom
                def foo(x, y); end
                def bar; end
                def baz; end
              end
            RBI
          },
          repo_name: "repo1",
        )

        repo2 = create_repo(
          {
            spoom: <<~RBI,
              # typed: true

              class AnnotationForSpoom
                def foo(x); end
                def bar(x); end
                def baz; end
              end
            RBI
          },
          repo_name: "repo2",
        )

        result = @project.tapioca("annotations --sources #{repo1.absolute_path} #{repo2.absolute_path}")

        assert_stderr_includes(result, <<~ERR)
          Can't import RBI file for `spoom` as it contains conflicts:
              Conflicting definitions for `::AnnotationForSpoom#foo(x, y)`
              Conflicting definitions for `::AnnotationForSpoom#bar()`
        ERR

        refute_includes(result.out, "create  sorbet/rbi/annotations/spoom.rbi")
        refute_project_file_exist("sorbet/rbi/annotations/spoom.rbi")

        repo1.destroy!
        repo2.destroy!
      end

      it "errors if passing both --no-netrc and --netrc-file" do
        result = @project.tapioca("annotations --no-netrc --netrc-file some_file")

        assert_stderr_includes(result, <<~ERR)
          Options `--no-netrc` and `--netrc-file` can't be used together
        ERR

        refute_success_status(result)
      end

      it "overrides strictnesses in annotations files" do
        repo = create_repo({
          rbi: <<~RBI,
            # typed: strict

            class AnnotationForRBI; end
          RBI
          spoom: <<~RBI,
            class AnnotationForSpoom; end
          RBI
        })

        result = @project.tapioca("annotations --sources #{repo.absolute_path} --typed-overrides rbi:ignore spoom:true")

        assert_project_annotation_equal("sorbet/rbi/annotations/rbi.rbi", <<~RBI)
          # typed: ignore

          # DO NOT EDIT MANUALLY
          # This file was pulled from a central RBI files repository.
          # Please run `bin/tapioca annotations` to update it.

          class AnnotationForRBI; end
        RBI

        assert_project_annotation_equal("sorbet/rbi/annotations/spoom.rbi", <<~RBI)
          # typed: true

          # DO NOT EDIT MANUALLY
          # This file was pulled from a central RBI files repository.
          # Please run `bin/tapioca annotations` to update it.

          class AnnotationForSpoom; end
        RBI

        assert_success_status(result)

        repo.destroy!
      end
    end

    private

    sig { params(annotations: T::Hash[String, String], repo_name: String).returns(Spoom::Context) }
    def create_repo(annotations, repo_name: "repo")
      repo = Spoom::Context.new("#{@project.absolute_path}/#{repo_name}")
      repo.mkdir!
      index = {}

      annotations.each do |gem_name, rbi_content|
        index[gem_name] = {}
        repo.write!("rbi/annotations/#{gem_name}.rbi", rbi_content)
      end

      repo.write!("index.json", index.to_json)
      repo
    end

    sig { params(path: String, content: String).void }
    def assert_project_annotation_equal(path, content)
      assert_equal(content, @project.read(path))
    end
  end
end
