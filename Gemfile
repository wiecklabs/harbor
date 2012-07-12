source "http://rubygems.org"

gemspec

group :development, :test do
  gem 'ci_reporter', '1.7.0'
  gem 'test-unit', '~> 2.0.0'
  # Pretty printed test output
  gem 'turn', :require => false
end

platforms :ruby do
  gem "rack"
end

platforms :jruby do
  gem "jruby-rack"
  gem "jruby-openssl"
end
