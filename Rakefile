require "rubygems"
require "pathname"
require "rake"
require "spec/rake/spectask"

# Specs
task :default => :spec
Spec::Rake::SpecTask.new("spec") do |t|
  t.spec_opts << "--colour" << "--loadby" << "random"
  t.spec_files = Dir["spec/**/*_spec.rb"]
end

# rcov
Spec::Rake::SpecTask.new("rcov") do |t|
  t.spec_opts << "--colour" << "--loadby" << "random"
  t.rcov = true
  t.spec_files = Dir["spec/**/*_spec.rb"]
  t.rcov_opts << "--exclude" << "spec,environment.rb"
  t.rcov_opts << "--text-summary"
  t.rcov_opts << "--sort" << "coverage" << "--sort-reverse"
end

# Performance
task :perf => :performance
task :performance do
  puts `ruby #{Pathname(__FILE__).dirname + "script/performance.rb"}`
end

# Gem

require "rake/gempackagetask"

NAME = "wheels"
SUMMARY = "Wheels Framework"
GEM_VERSION = "0.1.3"

spec = Gem::Specification.new do |s|
  s.name = NAME
  s.summary = s.description = SUMMARY
  s.author = "Wieck Media"
  s.email = "dev@wieck.com"
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.files = %w(Rakefile) + Dir.glob("lib/**/*")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Install Wheels as a gem"
task :install => [:repackage] do
  sh %{gem install pkg/#{NAME}-#{GEM_VERSION}}
end

desc "Publish Wheels gem"
task :publish do
  STDOUT.print "Publishing gem... "
  STDOUT.flush
  `ssh gems@able.wieck.com "cd wheels && git pull &> /dev/null && rake repackage &> /dev/null && cp pkg/* ../site/gems && cd ../site && gem generate_index"`
  STDOUT.puts "done"
end