require "rubygems"
require "bundler/setup"
require "pathname"
require "rake"
require "rdoc/task"
require "rake/testtask"

# Tests
task :default => [:test]

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end

desc "Run tests with code coverage enabled"
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task["test"].execute
end

task :rdoc do
  sh <<EOS.strip
rdoc -T harbor#{" --op " + ENV["OUTPUT_DIRECTORY"] if ENV["OUTPUT_DIRECTORY"]} --line-numbers --main README --title "Harbor Documentation" --exclude "lib/harbor/commands/*" lib/harbor.rb lib/harbor README
EOS
end

# Gem
require "bundler/gem_tasks"
