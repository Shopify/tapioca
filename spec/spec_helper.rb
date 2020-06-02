# typed: strict
# frozen_string_literal: true

require "tapioca"
require "rubocop/rspec/support"

RSpec.configure do |config|
  config.include(RuboCop::RSpec::ExpectOffense)

  config.expect_with(:rspec) do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with(:rspec) do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching(:focus)
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  Kernel.srand(config.seed)

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end
end

def run_in_child
  read, write = IO.pipe

  pid = fork do
    Tapioca.silence_warnings do
      read.close
      result = yield
      write.puts(result)
    end
  end

  write.close
  Process.wait(pid)
  read.read.chomp
ensure
  read&.close
end

def with_contents(contents, requires: [contents.keys.first], &block)
  Dir.mktmpdir do |path|
    dir = Pathname.new(path)
    # Create a "lib" folder
    Dir.mkdir(dir.join("lib"))

    contents.each do |file, content|
      # Add our contents into their files in lib folder
      File.write(dir.join("lib/#{file}"), content)
    end

    run_in_child do
      # Require files
      requires.each do |file|
        require(dir.join("lib/#{file}"))
      end

      block.call(dir)
    end
  end
end

def with_content(content, &block)
  with_contents({ "file.rb" => content }, &block)
end

module RSpec
  module Matchers
    class Binding
      def ruby_version(selector)
        Gem::Requirement.new(selector).satisfied_by?(Gem::Version.new(RUBY_VERSION))
      end

      def erb_bindings
        binding
      end
    end

    ERB_SUPPORTS_KVARGS = ::ERB.instance_method(:initialize).parameters.assoc(:key)
    private_constant :ERB_SUPPORTS_KVARGS

    def template(src)
      erb = if ERB_SUPPORTS_KVARGS
        ::ERB.new(src, trim_mode: ">")
      else
        ::ERB.new(src, nil, ">")
      end

      erb.result(Binding.new.erb_bindings).chomp
    end
  end
end
