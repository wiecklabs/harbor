require "rubygems"
require "pathname"
require "rake"
require "spec/rake/spectask"

task :default => :spec
Spec::Rake::SpecTask.new("spec") do |t|
  t.spec_opts << "--colour" << "--loadby" << "random"
  t.spec_files = Dir["spec/**/*_spec.rb"]
end

Spec::Rake::SpecTask.new("rcov") do |t|
  t.spec_opts << "--colour" << "--loadby" << "random"
  t.rcov = true
  t.spec_files = Dir["spec/**/*_spec.rb"]
  t.rcov_opts << "--exclude" << "spec,environment.rb"
  t.rcov_opts << "--text-summary"
  t.rcov_opts << "--sort" << "coverage" << "--sort-reverse"
end

task :perf => :performance
task :performance do
  puts `ruby #{Pathname(__FILE__).dirname + "script/performance.rb"}`
end