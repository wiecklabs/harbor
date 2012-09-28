<<<<<<< HEAD
source :gemcutter

gem "testdrive"
gem "builder"
gem "datamapper"
gem "dm-sqlite-adapter"
gem "do_sqlite3"
gem "dm-migrations"
gem "erubis"
gem "i18n"
gem "logging"
gem "mail_builder"
gem "rack"
gem "rack-test"
gem "rake"
gem "redis_directory", :git => "git@github.com:sam/redis_directory.git"
gem "uuid"
gem "autotest-fsevent"
gem "active_support"

group :development, :test do
  gem 'ci_reporter', '1.7.0'
  # Pretty printed test output
  gem 'turn', :require => false
end
=======
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
>>>>>>> afcda6833a461947da81fee3e28965b762663c3e
