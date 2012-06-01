lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "harbor/version"

Gem::Specification.new do |s|
  s.name = "harbor"
  s.summary = s.description = "Harbor Framework"
  s.author = "Sam Smoot"
  s.homepage = "https://github.com/sam/harbor"
  s.email = "ssmoot@gmail.com"
  s.version = Harbor::VERSION
  s.platform = Gem::Platform::RUBY
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = "harbor"
  s.require_paths = ["lib"]

  s.add_development_dependency "rack-test"
  s.add_development_dependency "do_sqlite3"
  s.add_development_dependency "testdrive"
  s.add_development_dependency "rake"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "rdoc", ">= 2.4.2"
  s.add_development_dependency "erubis"
  s.add_development_dependency "builder"
  s.add_development_dependency "redis_directory", ">= 1.0.4"
  s.add_development_dependency "minitest"
  s.add_development_dependency "mocha"
  s.add_development_dependency "listen"

  s.add_runtime_dependency "mime-types"
  s.add_runtime_dependency "uuidtools"
  s.add_runtime_dependency "tilt"
  s.add_runtime_dependency "logging"
  s.add_runtime_dependency "sprockets"
end
