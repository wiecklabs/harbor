require_relative 'helper'
require "harbor/commands/setup"

class HarborSetupCommandTest < MiniTest::Unit::TestCase

  def setup
    @temp_path = File.join(File.dirname(__FILE__), "tmp")
  end

  def teardown
    FileUtils.rm_rf(@temp_path) if File.directory?(@temp_path)
  end

  def test_generator_creates_expected_app_structure
    app_root = File.join(@temp_path, "petshop")
    FileUtils.mkdir_p(app_root)

    Harbor::Commands::Setup.new('petshop', app_root, nil).run

    expected_generated_file_and_directory_list = %w{
      test/tmp/petshop/controllers
      test/tmp/petshop/controllers/home.rb
      test/tmp/petshop/env
      test/tmp/petshop/env/default.rb
      test/tmp/petshop/env/stage.rb
      test/tmp/petshop/env/production.rb
      test/tmp/petshop/forms
      test/tmp/petshop/forms/example.rb
      test/tmp/petshop/helpers
      test/tmp/petshop/helpers/general.rb
      test/tmp/petshop/lib
      test/tmp/petshop/lib/boot.rb
      test/tmp/petshop/lib/petshop.rb
      test/tmp/petshop/log
      test/tmp/petshop/models
      test/tmp/petshop/public
      test/tmp/petshop/public/images
      test/tmp/petshop/public/javascripts
      test/tmp/petshop/public/stylesheets
      test/tmp/petshop/views
      test/tmp/petshop/views/layouts
      test/tmp/petshop/views/layouts/application.html.erb
      test/tmp/petshop/views/home
      test/tmp/petshop/views/home/index.html.erb
    }

    assert_equal expected_generated_file_and_directory_list.sort, Dir["#{app_root}/**/*"].sort
  end

end
