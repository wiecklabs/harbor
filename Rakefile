require "rubygems"
require "rake"
require "spec/rake/spectask"

task :default => :spec
Spec::Rake::SpecTask.new("spec") do |t|
  t.spec_opts << '--colour' << '--loadby' << 'random'
  t.spec_files = Dir["spec/**/*_spec.rb"]
end