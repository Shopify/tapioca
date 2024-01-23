# typed: true
# frozen_string_literal: true

require "yard"
require "tapioca"
require "tapioca/runtime/reflection"

YARD::Rake::YardocTask.new(:yard_for_generate_documentation) do |task|
  task.files = ["lib/tapioca/dsl/compilers/**/*.rb"]
  task.options = ["--no-output"]
end

desc("Generate docs of all DSL compilers")
task generate_dsl_documentation: :yard_for_generate_documentation do
  def assert_manual_synchronized
    # Do not print diff and yield whether exit code was zero
    sh('test -z "$(git status --porcelain manual)"') do |outcome, _|
      return if outcome

      # Output diff before raising error
      sh("git status --porcelain manual")

      warn(<<~WARNING)
        The manual directory is out of sync.
        Run `bin/docs` (or `dev docs`) and commit the results.
      WARNING

      exit!
    end
  end

  def table_contents(registry)
    registry
      .filter_map do |entry|
        "* #{entry.link}"
      end
      .join("\n")
  end

  def print_table_of_contents(registry)
    path = "#{Dir.pwd}/manual/compilers.md"
    original = File.read(path)
    content = +"<!-- START_COMPILER_LIST -->\n"

    content << table_contents(registry)

    content << "\n<!-- END_COMPILER_LIST -->"

    content = if original.empty?
      content
    else
      original.sub(
        /<!-- START_COMPILER_LIST -->.+<!-- END_COMPILER_LIST -->/m, content
      )
    end
    File.write(path, content)
  end

  def compiler_body(registry_entry)
    content = +"## #{registry_entry.name}\n"
    content << "\n"
    content << "#{registry_entry.description}\n"
    content
  end

  def print_compilers(registry)
    registry.each do |entry|
      File.write(entry.filename, compiler_body(entry))
    end
  end

  def load_registry
    YARD::Registry.all(:class).filter_map do |code_object|
      next unless code_object.superclass.to_s == "Tapioca::Dsl::Compiler"

      RegistryEntry.new(code_object.name.to_s, code_object)
    end.sort_by(&:name)
  end

  RegistryEntry = Struct.new(:name, :code_object) do
    def filename
      "#{Dir.pwd}/manual/compiler_#{name.downcase}.md"
    end

    def filebasename
      File.basename(filename)
    end

    def link
      "[#{name}](#{filebasename})"
    end

    def description
      if code_object.docstring.blank?
        "[No description provided]"
      else
        code_object.docstring
      end
    end
  end

  def main
    Dir.glob("lib/tapioca/dsl/{compiler.rb,compilers/**/*.rb}") { |file| YARD.parse(file) }
    registry = load_registry

    print_table_of_contents(registry)
    print_compilers(registry)

    assert_manual_synchronized if ENV["CI"] == "true"
  end

  main
end
