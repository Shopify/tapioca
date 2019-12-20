# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError # rubocop:disable Lint/SuppressedException
end

task(default: :spec)
