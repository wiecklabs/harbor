require "rubygems"
require "pathname"
require 'ci/reporter/rake/minitest'

unless ENV["TRAVIS"]
  require "bundler/setup"
  require "bundler/gem_tasks"
end

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
  if RUBY_PLATFORM =~ /java/
    puts "Simplecov doesn't play well with Java, see http://jira.codehaus.org/browse/JRUBY-6106 for more info"
    exit(1)
  end

  ENV['COVERAGE'] = 'true'
  Rake::Task["test"].execute
end

task :rdoc do
  sh <<EOS.strip
rdoc -T harbor#{" --op " + ENV["OUTPUT_DIRECTORY"] if ENV["OUTPUT_DIRECTORY"]} --line-numbers --main README --title "Harbor Documentation" --exclude "lib/harbor/commands/*" lib/harbor.rb lib/harbor README
EOS
end
