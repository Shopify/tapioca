# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
Dir["tasks/**/*.rake"].each { |t| load t }

Rake.application.options.trace = false

Rake::TestTask.new do |t|
  t.libs << "lib"
  t.libs << "spec"
  t.warning = false
  t.test_files = FileList["spec/**/*_spec.rb"]
end

task(:spec) do
  Rake::Task[:test].execute
rescue RuntimeError
  exit(1)
end

task(default: :spec)
