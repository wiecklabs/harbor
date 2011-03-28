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
  s.require_path = 'lib'
  s.files = %w(Rakefile) + Dir.glob("lib/**/*")
  s.executables = ['harbor','apache_importer','page_view_reconciler']

  s.add_dependency "builder"
  s.add_dependency "erubis"
  s.add_dependency "logging"
  s.add_dependency "mail_builder"
  s.add_dependency "rack", "~> 1.0.0"
  s.add_dependency "thin"
end
