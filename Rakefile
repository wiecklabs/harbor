require "rubygems"
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

# rdoc

# desc "Generate RDoc documentation"
# Rake::RDocTask.new(:rdoc) do |rdoc|
#   rdoc.options << '--line-numbers' << '--inline-source' <<
#     '--main' << 'README' <<
#     '--title' << 'Harbor Documentation' <<
#     '--charset' << 'utf-8' << "--exclude" << "lib/harbor/generator/"
#   rdoc.rdoc_dir = "doc"
#   rdoc.rdoc_files.include 'README'
#   rdoc.
#   rdoc.rdoc_files.include('lib/rack.rb')
#   rdoc.rdoc_files.include('lib/rack/*.rb')
#   rdoc.rdoc_files.include('lib/rack/*/*.rb')
# end

task :rdoc do
  sh <<-EOS.strip
rdoc -T harbor#{" --op " + ENV["OUTPUT_DIRECTORY"] if ENV["OUTPUT_DIRECTORY"]} --line-numbers --main README --title "Harbor Documentation" --exclude "lib/harbor/generator/*" lib/harbor.rb lib/harbor README
  EOS
end

# Performance
task :perf => :performance
task :performance do
  puts `ruby #{Pathname(__FILE__).dirname + "script/performance.rb"}`
end

# Gem
require "bundler/gem_tasks"
