# frozen_string_literal: true

require "bundler/gem_tasks"
Dir["tasks/**/*.rake"].each { |t| load t }

require "rubocop/rake_task"
RuboCop::RakeTask.new

desc "Run tests"
task :test do
  require "shellwords"
  test = Array(ENV.fetch("TEST", []))
  test_opts = Shellwords.split(ENV.fetch("TESTOPTS", ""))
  success = system("bin/test", *test, *test_opts)
  success || exit(false)
end

task(default: :test)
