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

    def template(src)
      ERB.new(src, nil, ">").result(Binding.new.erb_bindings).chomp
    end
  end
end
