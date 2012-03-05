lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'harbor/version'

Gem::Specification.new do |s|
  s.name = 'harbor'
  s.summary = s.description = 'Harbor Framework'
  s.author = "Wieck Media"
  s.homepage = "http://wiecklabs.com"
  s.email = "dev@wieck.com"
  s.version = Harbor::VERSION
  s.platform = Gem::Platform::RUBY
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rack-test"
  s.add_development_dependency "do_sqlite3"
  s.add_development_dependency "testdrive"
  s.add_development_dependency "rake"
  s.add_development_dependency "uuid"
  s.add_development_dependency "rdoc", ">= 2.4.2"
  s.add_development_dependency "erubis"
  s.add_development_dependency "redis_directory", ">= 1.0.4"

  s.add_runtime_dependency "mime-types"
  s.add_runtime_dependency "uuidtools"
  s.add_runtime_dependency "builder"
  s.add_runtime_dependency "tilt"
  s.add_runtime_dependency "logging"
end
