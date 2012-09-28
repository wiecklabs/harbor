require_relative 'helper'

class AutoloaderTest < MiniTest::Unit::TestCase
  class ::AutoloadApp
    def self.root
      (Pathname(__FILE__).dirname + "fixtures/autoload/application").expand_path
    end
  end

  def setup
    Harbor.stubs(:registered_applications => [AutoloadApp])
    config.autoloader.paths << Pathname(__FILE__).dirname + "fixtures/autoload"
  end

  def teardown
    config.autoloader.paths.clear
    Object.instance_eval do
      [:ModuleWithFiles, :ClassOnRootPath, :EmptyModule, :AutoloadedAppModel, :OtherLibClass, :LibModule].each do |const|
        remove_const const if const_defined? const
      end
    end
    AutoloadApp.instance_eval do
      [:SomeLibClass, :Controllers, :AppModel, :Models, :Lib, :Env, :Assets, :Log, :Public, :Views].each do |const|
        remove_const const if const_defined? const
      end
    end
    Dir[Pathname(__FILE__).dirname + "fixtures/autoload/**/*.rb"].each do |file|
      $LOADED_FEATURES.delete File.expand_path file
    end
  end

  def test_autoloads_classes_under_registered_paths
    ::ClassOnRootPath
  end

  def test_creates_module_for_folders
    ::ModuleWithFiles::SomeClass
  end

  def test_does_not_create_module_for_empty_folders
    assert_raises NameError do
      ::EmptyModule
    end
  end

  def test_autoloads_application_classes
    AutoloadApp::SomeLibClass
    AutoloadApp::Controllers::SomeController
  end

  def test_autoloads_application_models_without_application_namespace
    ::AutoloadedAppModel
  end

  def test_autoloads_application_models_without_models_namespace
    AutoloadApp::AppModel
  end

  def test_autoloads_application_lib_classes_without_application_namespace
    ::OtherLibClass::InnerClass
    ::LibModule::LibClass
  end

  def test_does_not_load_file_on_application_root
    assert_raises NameError do
      AutoloadApp::RootFile
    end
  end

  def test_does_not_create_module_for_application_lib_folder
    assert_raises NameError do
      AutoloadApp::Lib
    end
  end

  def test_does_not_create_module_for_application_env_folder
    assert_raises NameError do
      AutoloadApp::Env
    end
  end

  def test_does_not_create_module_for_application_assets_folder
    assert_raises NameError do
      AutoloadApp::Assets
    end
  end

  def test_does_not_create_module_for_application_log_folder
    assert_raises NameError do
      AutoloadApp::Log
    end
  end

  def test_does_not_create_module_for_application_public_folder
    assert_raises NameError do
      AutoloadApp::Public
    end
  end

  def test_does_not_create_module_for_application_views_folder
    assert_raises NameError do
      AutoloadApp::Views
    end
  end
end
