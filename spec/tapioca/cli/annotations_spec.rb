# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  class AnnotationsTest < SpecWithProject
    describe "cli::annotations" do
      before(:all) do
        @project.bundle_install
      end

      after do
        @project.remove("sorbet/rbi/annotations")
      end

      it "does nothing if the repo is empty" do
        repo = create_repo({})

        result = @project.tapioca("annotations --repo-uri #{repo.path}")

        assert_equal(<<~OUT, result.out)
          Retrieving index from central repository... Done
          Listing gems from Gemfile.lock... Done
          Removing annotations for gems that have been removed...  Nothing to do
          Fetching gem annotations from central repository...  Nothing to do
        OUT

        assert_success_status(result)

        repo.destroy
      end

      it "removes local annotations if they do not appear in the Gemfile.lock" do
        repo = create_repo({})

        @project.write("sorbet/rbi/annotations/rbi.rbi", "# typed: true")
        @project.write("sorbet/rbi/annotations/bar.rbi", "# typed: true")
        @project.write("sorbet/rbi/annotations/foo.rbi", "# typed: true")

        result = @project.tapioca("annotations --repo-uri #{repo.path}")

        assert_includes(result.out, "remove  sorbet/rbi/annotations/bar.rbi")
        assert_includes(result.out, "remove  sorbet/rbi/annotations/foo.rbi")
        refute_includes(result.out, "remove  sorbet/rbi/annotations/rbi.rbi")

        assert_success_status(result)

        repo.destroy
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

        result = @project.tapioca("annotations --repo-uri #{repo.path}")

        assert_includes(result.out, "create  sorbet/rbi/annotations/rbi.rbi")
        assert_includes(result.out, "create  sorbet/rbi/annotations/spoom.rbi")
        refute_includes(result.out, "create  sorbet/rbi/annotations/foo.rbi")

        assert_project_annotation_equal(repo, "sorbet/rbi/annotations/rbi.rbi", <<~RBI)
          # typed: true

          # DO NOT EDIT MANUALLY
          # This file was pulled from $REPO_PATH.
          # Please run `bin/tapioca annotations` to update it.

          class AnnotationForRBI; end
        RBI

        assert_project_annotation_equal(repo, "sorbet/rbi/annotations/spoom.rbi", <<~RBI)
          # typed: strict

          # DO NOT EDIT MANUALLY
          # This file was pulled from $REPO_PATH.
          # Please run `bin/tapioca annotations` to update it.

          class AnnotationForSpoom; end
        RBI

        refute_project_file_exist("sorbet/rbi/annotations/foo.rbi")
        assert_success_status(result)

        repo.destroy
      end
    end

    private

    sig { params(annotations: T::Hash[String, String]).returns(MockDir) }
    def create_repo(annotations)
      repo = MockDir.new("#{@project.path}/repo")
      index = {}

      annotations.each do |gem_name, rbi_content|
        index[gem_name] = {}
        repo.write("rbi/annotations/#{gem_name}.rbi", rbi_content)
      end

      repo.write("index.json", index.to_json)
      repo
    end

    sig { params(repo: MockDir, path: String, content: String).void }
    def assert_project_annotation_equal(repo, path, content)
      rbi_annotation = @project.read(path)
      assert_equal(content.strip, rbi_annotation.gsub(repo.path, "$REPO_PATH").strip)
    end
  end
end
