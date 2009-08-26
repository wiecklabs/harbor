require "rubygems"
require "pathname"
require "rake"
require "rake/rdoctask"
require "rake/testtask"
require "spec/rake/spectask"

# Specs
task :default => [:spec, :test]

Spec::Rake::SpecTask.new("spec") do |t|
  t.spec_opts << "--colour" << "--loadby" << "random"
  t.spec_files = Dir["spec/**/*_spec.rb"]
end

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
  sh 'rm -r doc' if File.directory?('doc')
  begin
    sh 'sdoc --line-numbers --inline-source --main "README" --title "Harbor Documentation" --exclude lib/harbor/generator/* README lib'
  rescue
    puts "sdoc not installed:"
    puts "  gem install voloko-sdoc --source http://gems.github.com"
  end
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

NAME = "harbor"
SUMMARY = "Harbor Framework"
GEM_VERSION = "0.12"

spec = Gem::Specification.new do |s|
  s.name = NAME
  s.summary = s.description = SUMMARY
  s.author = "Wieck Media"
  s.homepage = "http://wiecklabs.com"
  s.email = "dev@wieck.com"
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.files = %w(Rakefile) + Dir.glob("lib/**/*")
  s.executables = ['harbor']

  s.add_dependency "rack", "~> 1.0.0"
  s.add_dependency "erubis"

end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Install Harbor as a gem"
task :install => [:repackage] do
  sh %{gem install pkg/#{NAME}-#{GEM_VERSION}}
end

desc "Publish Harbor gem"
task :publish do
  STDOUT.print "Publishing gem... "
  STDOUT.flush
  `git tag -a #{GEM_VERSION} -m "v. #{GEM_VERSION}" &> /dev/null`
  `git push --tags &> /dev/null`

  commands = [
    "if [ ! -d '#{NAME}' ]; then git clone git://github.com/wiecklabs/harbor.git; fi",
    "cd #{NAME}",
    "git pull &> /dev/null",
    "rake repackage &> /dev/null",
    "cp pkg/* ../site/gems",
    "cd ../site",
    "gem generate_index"
  ]

  `ssh gems@able.wieck.com "#{commands.join(" && ")}"`
  STDOUT.puts "done"
end
