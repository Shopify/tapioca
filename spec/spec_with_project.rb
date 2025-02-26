# typed: strict
# frozen_string_literal: true

require "helpers/mock_project"

module Tapioca
  class SpecWithProject < Minitest::HooksSpec
    extend T::Sig

    TEST_TMP_PATH = "/tmp/tapioca/tests"

    # Spec lifecycle

    # TODO: Replace with `before(:all)` once Sorbet understands it
    #: (*untyped args) -> void
    def initialize(*args)
      super(*T.unsafe(args))
      @project = mock_project #: MockProject
    end

    # TODO: Remove this `before(:all)` once Sorbet understands `after(:all)` or instance variables access after a bind
    #: MockProject
    attr_reader :project

    after(:all) do
      project.destroy!
    end

    # Spec helpers

    # Create a new mock project for this spec
    #
    # Example:
    # ~~~
    # project = mock_project do
    #   write("lib/foo.rb")
    # end
    #
    # assert(@project.file?("lib/foo.rb"))
    # ~~~
    #: (?sorbet_dependency: bool) ?{ (MockProject gem) [self: MockProject] -> void } -> MockProject
    def mock_project(sorbet_dependency: true, &block)
      project = MockProject.new("#{TEST_TMP_PATH}/#{spec_name}/project")
      project.write_gemfile!(project.tapioca_gemfile)
      # Pin Sorbet static and runtime version to the current one in this project
      project.require_real_gem(
        "sorbet-static-and-runtime",
        ::Gem::Specification.find_by_name("sorbet-static-and-runtime").version.to_s,
      ) if sorbet_dependency
      project.instance_exec(project, &block) if block
      project
    end

    # Create a new mock gem
    #
    #
    # Example:
    # ~~~
    # gem = mock_gem("foo", "1.0.0") do
    #   write("lib/foo.rb")
    # end
    #
    # assert(@gem.file?("lib/foo.rb"))
    # ~~~
    #: (String name, String version, ?dependencies: Array[String], ?path: String) ?{ (MockGem gem) [self: MockGem] -> void } -> MockGem
    def mock_gem(name, version, dependencies: [], path: default_gem_path(name), &block)
      gem = MockGem.new(path, name, version, dependencies)
      gem.mkdir!
      gem.gemspec(gem.default_gemspec_contents)
      gem.instance_exec(gem, &block) if block
      gem
    end

    # Spec assertions

    # Assert that the contents of `path` inside `@project` is equals to `expected`
    #: (String path, String expected) -> void
    def assert_project_file_equal(path, expected)
      assert_equal(expected, @project.read(path))
    end

    # Assert that the contents of `path` inside `@project` includes `expected`
    #: (String path, String expected) -> void
    def assert_project_file_includes(path, expected)
      assert_includes(@project.read(path), expected)
    end

    # Assert that `path` exists inside `@project`
    #: (String path) -> void
    def assert_project_file_exist(path)
      assert(@project.file?(path))
    end

    # Assert that `path` exists inside project.
    # `Path` can include patterns such as `*`, useful for testing RBIs for real gems
    #: (String path) -> void
    def assert_project_file_match(path)
      assert(@project.glob(path).any?)
    end

    # Refute that `path` exists inside `@project`
    #: (String path) -> void
    def refute_project_file_exist(path)
      refute(@project.file?(path))
    end

    # Refute that `path` exists inside `@project`
    # `Path` can include patterns such as `*`, useful for testing RBIs for real gems
    #: (String path) -> void
    def refute_project_file_match(path)
      refute(@project.glob(path).any?)
    end

    #: (String strictness, String file) -> void
    def assert_file_strictness(strictness, file)
      assert_equal(strictness, Spoom::Sorbet::Sigils.file_strictness(@project.absolute_path_to(file)))
    end

    #: (Spoom::ExecResult result) -> void
    def assert_empty_stdout(result)
      assert_empty(result.out, result.to_s)
    end

    #: (Spoom::ExecResult result) -> void
    def assert_empty_stderr(result)
      assert_empty(result.err, result.to_s)
    end

    #: (Spoom::ExecResult result) -> void
    def assert_success_status(result)
      assert(result.status, result.to_s)
    end

    #: (Spoom::ExecResult result) -> void
    def refute_success_status(result)
      refute(result.status, result.to_s)
    end

    #: (String text, Spoom::ExecResult result) -> void
    def assert_stdout_equals(text, result)
      if ENV["TAPIOCA_ASSERTIONS_UPDATE"] && (text != result.out)
        SpecWithProject.assertion_update(:assert_stdout_equals, result.out)
      end

      assert_equal(text, result.out, result.to_s)
    end

    #: (String text, Spoom::ExecResult result) -> void
    def assert_stderr_equals(text, result)
      if ENV["TAPIOCA_ASSERTIONS_UPDATE"] && (text != result.err)
        SpecWithProject.assertion_update(:assert_stderr_equals, result.err || "")
      end

      assert_equal(text, result.err, result.to_s)
    end

    # There are many places where we assert directly against the output of
    # stdout as a snapshot of what is correct. This is useful to ensure we get
    # the exact output we want. However, this becomes a pain to update when
    # there are a bunch of snapshots that need to change. As such, we provide
    # this small helper to make it easier to update the snapshots. You can do
    # this by running the test suite with TAPIOCA_ASSERTIONS_UPDATE=1.
    #
    # Note that this is not meant to be committed directly. This is meant as a
    # helper for making development easier. The diff that this creates should be
    # checked carefully.
    if ENV["TAPIOCA_ASSERTIONS_UPDATE"]
      @assertion_updates = {} #: Hash[String, Array[[Integer, Symbol, String]]]

      class << self
        extend T::Sig

        #: Hash[String, Array[[Integer, Symbol, String]]]
        attr_reader :assertion_updates

        #: (Symbol type, String actual) -> void
        def assertion_update(type, actual)
          location = caller_locations.find { |caller_location| caller_location.path&.end_with?("_spec.rb") }
          absolute_path = location&.absolute_path
          (assertion_updates[absolute_path] ||= []) << [location.lineno, type, actual] if absolute_path
        end
      end

      # After the run, read each file that has assertions that need to be
      # updated, go through the assertions in backward order (so that the line
      # numbers don't change), and insert the correct value into the spot where
      # the heredoc was.
      Minitest.after_run do
        ::Tapioca::SpecWithProject.assertion_updates.each do |absolute_path, assertions|
          source = File.readlines(absolute_path)

          assertions.sort_by { |assertion| -assertion[0] }.each do |start_lineno, type, actual|
            next unless (name = (source.fetch(start_lineno - 1).scan(/#{type}\(<<~([A-Z]+)/)[0] || [])[0])

            end_lineno =
              T.must(source[start_lineno..]).find.with_index(start_lineno) do |line, lineno|
                break lineno if line.match?(/^\s+#{name}\r?\n$/)
              end

            next unless end_lineno

            indent = T.must(source.fetch(start_lineno)[/\A\s+/, 0]).length
            source[start_lineno...end_lineno] =
              actual.lines.map { |line| line.strip.empty? ? line : "#{" " * indent}#{line}" }
          end

          File.write(absolute_path, source.join)
        end
      end
    end

    #: (Spoom::ExecResult result, String snippet) -> void
    def assert_stdout_includes(result, snippet)
      assert_includes(result.out, snippet, result.to_s)
    end

    #: (Spoom::ExecResult result, Regexp pattern) -> void
    def assert_stdout_includes_pattern(result, pattern)
      assert_match(pattern, result.out.to_s, result.to_s)
    end

    #: (Spoom::ExecResult result, String snippet) -> void
    def assert_stderr_includes(result, snippet)
      assert_includes(result.err, snippet, result.to_s)
    end

    #: (Spoom::ExecResult result, Regexp pattern) -> void
    def assert_stderr_includes_pattern(result, pattern)
      assert_match(pattern, result.err.to_s, result.to_s)
    end

    private

    #: (String name) -> String
    def default_gem_path(name)
      "#{TEST_TMP_PATH}/#{spec_name}/gems/#{name}"
    end

    #: -> String
    def spec_name
      spec_class = T.unsafe(self).class
      spec_class = spec_class.superclass while spec_class.superclass != SpecWithProject
      name = spec_class.name&.split("::")&.last
      name.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
      name.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      name.downcase!
      name
    end
  end
end
