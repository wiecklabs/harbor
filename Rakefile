require "rubygems"
require "pathname"
require "rake"
require "spec/rake/spectask"

task :default => :spec
Spec::Rake::SpecTask.new("spec") do |t|
  t.spec_opts << '--colour' << '--loadby' << 'random'
  t.spec_files = Dir["spec/**/*_spec.rb"]
end

task :perf => :performance
task :performance do
  puts `ruby #{Pathname(__FILE__).dirname + "script/performance.rb"}`
end