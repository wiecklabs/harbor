require 'sequel'
require 'do_sqlite3'

class SequelTestCase < Test::Unit::TestCase

  DB = Sequel.connect('do:sqlite3::memory:')

  def run(*args, &block)
    Sequel::Model.db.transaction(:rollback=>:always){super}
  end
end
