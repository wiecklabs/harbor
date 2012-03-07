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
      petshop/Gemfile
      petshop/config.ru
      petshop/controllers
      petshop/controllers/home.rb
      petshop/env
      petshop/env/default.rb
      petshop/env/development.rb
      petshop/env/stage.rb
      petshop/env/testing.rb
      petshop/env/production.rb
      petshop/forms
      petshop/forms/example.rb
      petshop/helpers
      petshop/helpers/general.rb
      petshop/lib
      petshop/lib/boot.rb
      petshop/lib/petshop.rb
      petshop/log
      petshop/models
      petshop/public
      petshop/public/images
      petshop/public/javascripts
      petshop/public/stylesheets
      petshop/views
      petshop/views/layouts
      petshop/views/layouts/application.html.erb
      petshop/views/home
      petshop/views/home/index.html.erb
    }
    
    skeleton = Dir["#{app_root}/**/*"].map { |path| path.sub "#{@temp_path}/", "" } 
    assert_equal expected_generated_file_and_directory_list.sort, skeleton.sort
  end

end
